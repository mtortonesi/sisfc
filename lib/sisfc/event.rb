module SISFC

  class Event

    ET_REQUEST_ARRIVAL         = 0
    ET_WORKFLOW_STEP_COMPLETED = 1
    ET_VM_FREE                 = 2
    ET_VM_SUSPEND              = 3
    ET_VM_RESUME               = 4
    ET_REQUEST_CLOSURE         = 5
    ET_END_OF_SIMULATION       = 100

    # let the comparable mixin provide the < and > operators for us
    include Comparable

    # should this be attr_accessor instead?
    attr_reader :type, :data, :time, :destination

    def initialize(type, data, time, destination)
      @type        = type
      @data        = data
      @time        = time
      @destination = destination
    end

    def <=> (event)
      @time <=> event.time
    end

    def to_s
      "Event type: #{@type}, data: #{@data}, time: #{@time}, #{@destination}"
    end

  end

end
