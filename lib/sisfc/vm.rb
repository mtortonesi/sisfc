require 'sisfc/event'
require 'erv'


module SISFC

  class VM

    # setup readable/accessible attributes
    ATTRIBUTES = [ :vmid, :dc_id, :size ]

    attr_reader *ATTRIBUTES

    def initialize(vmid, opts)
      # make sure all the required opts were provided
      [ :dc_id, :vm_size, :service_time_distribution ].each do |k|
        raise ArgumentError, "opts[:#{k}] missing" unless opts.has_key? k
      end

      @vmid             = vmid
      @dcid             = opts[:dc_id]
      @size             = opts[:vm_size]
      @service_times_rv = ERV::RandomVariable.new(opts[:service_time_distribution][@size])

      # initialize request queue and related tracking information
      @busy          = false
      @request_queue = []

      # @request_queue_info          = []
      # @request_currently_servicing = nil
    end

    def new_request(sim, r, time)
      # put the (request, service time, arrival time) tuple at the end of the queue
      @request_queue << [ r, @service_times_rv.next, time ]

      # update queue size tracking information
      # @request_queue_info << { :size => @request_queue.size, :time => time }

      unless @busy
        # try to allocate operator
        try_servicing_new_request(sim, time)
      end
    end

    def request_finished(sim, time)
      @busy = false
      try_servicing_new_request(sim, time)
    end

    # def suspend(time)
    #   raise "VM is already suspended!" if @suspended
    #   @request_currently_servicing.finishing_time =
    #   @request_currently_servicing.status = Request::STATE_WORKING
    # end

    # def resume(time)
    #   raise "VM is already working!" unless @suspended
    # end

    private

      def try_servicing_new_request(sim, time)
        raise "Busy VM (vmid: #{@vmid})!" if @busy

        unless @request_queue.empty?
          # pick request and metadata from the incoming request queue
          req, service_time, arrival_time = @request_queue.shift

          # update the request's queuing information
          req.queuing_completed(arrival_time, time - arrival_time)

          # the VM is busy now
          @busy = true

          # update the request's working information
          req.step_completed(time, time + service_time)

          # schedule completion of workflow step
          sim.new_event(Event::ET_WORKFLOW_STEP_COMPLETED, req, time + service_time, self)
        end
      end

  end

end