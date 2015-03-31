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
      # setup simulation start and current time
      @current_time = @start_time = @configuration.start_time

      # create data centers
      data_centers = @configuration.data_centers.map {|k,v| DataCenter.new(k,v) }

      # initialize statistics
      stats    = Statistics.new
      dc_stats = data_centers.map {|k,v| Statistics.new }

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
          data_centers[opts[:dc_id]-1].add_vm(vm, opts[:component_type])
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

              # get random vm providing next service component type
              new_vm = data_center.get_random_vm(next_component_name)

              # forward request to the new vm
              new_vm.new_request(self, req, e.time)
            else # workflow is finished
              # schedule request closure
              new_event(Event::ET_REQUEST_CLOSURE, req, e.time + req.communication_latency, nil)
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
              dc_stats[req.data_center_id - 1].record_request(req)
            end


          when Event::ET_END_OF_SIMULATION
            # puts "#{e.time}: end simulation"
            break

        end
      end

      # puts "========== Simulation Finished =========="

      # calculate kpis (for the moment, we only have mttr)
      kpis = { :mttr            => stats.mean,
               :served_requests => stats.n,
               :queued_requests => requests_being_worked_on }
      dc_kpis = dc_stats.map do |s|
        { :mttr            => s.mean,
          :served_requests => s.n, }
      end
      fitness = @evaluator.evaluate_business_impact(kpis, dc_kpis, vm_allocation)
      puts "====== Evaluating new allocation ======\n" +
        vm_allocation.map{|x| x.except(:service_time_distribution) }.inspect + "\n" +
        "kpis: #{kpis.to_s}\n" +
        "dc_kpis: #{dc_kpis.to_s}\n" +
        "=======================================\n"
      fitness
    end

  end
end
