require 'sisfc/data_center'
require 'sisfc/event'
require 'sisfc/generator'
require 'sisfc/sorted_array'
require 'sisfc/statistics'
require 'sisfc/vm'


module SISFC
  class Simulation

    attr_reader :start_time


    def initialize(opts = {})
      @configuration = opts[:configuration]
      @evaluator     = opts[:evaluator]
    end


    def new_event(type, data, time, destination)
      e = Event.new(type, data, time, destination)
      @event_queue << e
    end


    def now
      @current_time
    end


    def evaluate_allocation(vm_allocation)
      # initialize request counters
      reqs_received = 0
      reqs_longer_than = init_counters_for_longer_than_stats(@configuration.kpi_customization)

      # setup simulation start and current time
      @current_time = @start_time = @configuration.start_time

      # create data centers
      data_centers = @configuration.data_centers.map {|k,v| DataCenter.new(k,v) }

      # initialize statistics
      stats = Statistics.new
      num_customers = @configuration.customers.size
      customer_stats = Array.new(num_customers) { Statistics.new }
      reqs_received_from_customer = Array.new(num_customers) { Statistics.new }

      # create VMs
      @vms = []
      vmid = 0
      vm_allocation.each do |opts|
        # setup service_time_distribution
        opts[:service_time_distribution] = @configuration.service_component_types[opts[:component_type]][:service_time_distribution]

        # allocate the VMs
        opts[:vm_num].times do
          # create VM ...
          vm = VM.new(vmid, opts[:dc_id], opts[:vm_size], opts[:service_time_distribution])
          # ... add it to the vm list ...
          @vms << vm
          # ... and register it in the corresponding data center
          unless data_centers[opts[:dc_id]-1].add_vm(vm, opts[:component_type])
            puts "====== Unfeasible allocation ======"
            # here we return Float::MAX instead of, e.g., Float::INFINITY,
            # because the latter would break optimization tools. instead, we
            # want to have a very high but comparable value.
            return Float::MAX
          end
          # update vm id
          vmid += 1
        end
      end

      # create event queue
      @event_queue = SortedArray.new

      # puts "========== Simulation Start =========="

      # generate first request
      rg = RequestGenerator.new(@configuration.request_generation)
      new_req = rg.generate
      new_event(Event::ET_REQUEST_ARRIVAL, new_req, new_req.arrival_time, nil)

      # schedule end of simulation
      unless @configuration.end_time.nil?
        # puts "Simulation ends at: #{@configuration.end_time}"
        new_event(Event::ET_END_OF_SIMULATION, nil, @configuration.end_time, nil)
      end

      # calculate warmup threshold
      warmup_threshold = @configuration.start_time + @configuration.warmup_duration.to_i

      requests_being_worked_on = 0
      requests_forwarded_to_other_dcs = 0
      events = 0

      # launch simulation
      until @event_queue.empty?
        e = @event_queue.shift

        events += 1
        # sanity check on simulation time flow
        if @current_time > e.time
          raise "Error: simulation time inconsistency for event #{events} " +
                "e.type=#{e.type} @current_time=#{@current_time}, e.time=#{e.time}"
        end

        @current_time = e.time

        case e.type
          when Event::ET_REQUEST_ARRIVAL
            # get request
            req = e.data

            # find data center
            data_center = data_centers[req.data_center_id-1]

            # update reqs_received_from_customer
            reqs_received_from_customer[req.customer_id] += 1

            # find next component name
            workflow = @configuration.workflow_types[req.workflow_type_id]
            next_component_name = workflow[:component_sequence][req.next_step][:name]

            # get random vm providing next service component type
            vm = data_center.get_random_vm(next_component_name)

            # forward request to the vm
            vm.new_request(self, req, e.time)

            # update stats
            if req.arrival_time > warmup_threshold
              # increase the number of requests being worked on
              requests_being_worked_on += 1
              reqs_received += 1
            end

            # generate next request
            new_req = rg.generate
            new_event(Event::ET_REQUEST_ARRIVAL, new_req, new_req.arrival_time, nil)


          # Leave these events for when we add VM migration support
          # when Event::ET_VM_SUSPEND
          # when Event::ET_VM_RESUME


          when Event::ET_WORKFLOW_STEP_COMPLETED
            # retrieve request and vm
            req = e.data
            vm  = e.destination

            # tell the old vm that it can start processing another request
            vm.request_finished(self, e.time)

            # find data center and workflow
            data_center = data_centers[req.data_center_id-1]
            workflow    = @configuration.workflow_types[req.workflow_type_id]

            # check if there are other steps left to complete the workflow
            if req.next_step < workflow[:component_sequence].size
              # find next component name
              next_component_name = workflow[:component_sequence][req.next_step][:name]

              # get random VM providing next service component type
              new_vm = data_center.get_random_vm(next_component_name)

              # this is the request's time of arrival at the new VM
              forwarding_time = e.time

              # there might not be a VM of the type we need in the current data
              # center, so look in the other data centers
              unless new_vm
                other_dcs = data_centers.collect_if {|x| x != dc }
                other_dcs = order_dcs(other_dcs, closest_to: dc)
                other_dcs.each do |dc|
                  new_vm = dc.get_random_vm(next_component_name)
                  if new_vm
                    # need to update data_center_id of request
                    req.data_center_id = dc.dcid

                    # keep track of transmission time
                    transmission_time =
                      @configuration.communication_latency(data_center.location_id,
                                                           dc.location_id)
                    req.update_transfer_time(transmission_time)
                    forwarding_time += transmission_time

                    # update request's current data_center_id
                    req.data_center_id = dc.dcid

                    # keep track of number of requests forwarded to other data centers
                    requests_forwarded_to_other_dcs += 1

                    # we're done here
                    break
                  end
                end
              end

              # make sure we actually found a VM
              raise "Cannot find VM running a component of type " +
                    "#{next_component_name} in any data center!" unless new_vm

              # forward request to the new VM
              new_vm.new_request(self, req, forwarding_time)

            else # workflow is finished
              # calculate transmission time
              transmission_time =
                @configuration.communication_latency(
                  # data center location
                  data_center[req.data_center_id-1].location_id,
                  # customer location
                  @configuration.customers[req.customer_id][:location_id]
                )

              # keep track of transmission time
              req.update_transfer_time(transmission_time)

              # schedule request closure
              new_event(Event::ET_REQUEST_CLOSURE, req, e.time + transmission_time, nil)
            end


          when Event::ET_REQUEST_CLOSURE
            # retrieve request and vm
            req = e.data

            # request is closed
            req.finished_processing(e.time)

            # update stats
            if req.arrival_time > warmup_threshold
              # decrease the number of requests being worked on
              requests_being_worked_on -= 1

              # collect request statistics
              stats.record_request(req)
              ttr = req.ttr
              raise "TTR for request #{req.rid} is nil!" if ttr.nil?
              reqs_longer_than.each_key do |k|
                reqs_longer_than[k] += 1 if ttr > k
              end

              # collect request statistics in customer_stats
              customer_stats[req.customer_id].record_request(req)
            end


          when Event::ET_END_OF_SIMULATION
            # puts "#{e.time}: end simulation"
            break

        end
      end

      # puts "========== Simulation Finished =========="

      # poor man's statistics summary¬
      puts "received: #{reqs_received}, closed: #{stats.n}, " +
           "(mean: #{stats.mean}, sd: #{stats.variance}, gt: #{reqs_longer_than.to_s})"

      # calculate kpis (for the moment, we only have mttr)
      kpis = {
        mttr:            stats.mean,
        ttr_sd:          stats.variance,
        served_requests: stats.n,
        queued_requests: requests_being_worked_on,
        longer_than:     reqs_longer_than,
      }
      customer_kpis = customer_stats.each_with_index.map do |s,i|
        {
          mttr:              s.mean,
          ttr_sd:            s.variance,
          served_requests:   s.n,
          received_requests: reqs_received_from_customer[i],
        }
      end
      fitness = @evaluator.evaluate_business_impact(kpis, customer_kpis, vm_allocation)
      puts "====== Evaluating new allocation ======\n" +
        vm_allocation.map{|x| x.except(:service_time_distribution) }.inspect + "\n" +
        "kpis: #{kpis.to_s}\n" +
        "customer_kpis: #{customer_kpis.to_s}\n" +
        "=======================================\n"
      fitness
    end

    private
      def init_counters_for_longer_than_stats(custom_kpis_config)
        # prepare an infinite length enumerator that always returns zero
        zeros = Enumerator.new(){|x| loop do x << 0 end }

        Hash[
          # wrap the values in custom_kpis_config[:longer_than] in an array
          Array(custom_kpis_config[:longer_than]).
            # and interval the numbers contained in that array with zeroes
            zip(zeros) ]
      end

  end
end
