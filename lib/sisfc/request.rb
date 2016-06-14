module SISFC

  class Request

    # states
    STATE_WORKING   = 1
    STATE_SUSPENDED = 2

    attr_accessor :rid, :generation_time, :data_center_id, :arrival_time,
                  :workflow_type_id, :closure_time #, :status
    attr_reader :communication_latency

    def initialize(rid, generation_time, data_center_id, arrival_time, workflow_type_id)
      @rid              = rid
      @generation_time  = generation_time
      @data_center_id   = data_center_id
      @arrival_time     = arrival_time
      @workflow_type_id = workflow_type_id

      # steps count from zero
      @step = 0

      # calculate communication latency
      @communication_latency = @arrival_time - @generation_time

      # consider initial communication latency
      @tracking_information  = [
        {
          type:     :communication,
          at:       @generation_time,
          duration: @communication_latency,
        }
      ]

      # NOTE: the format for each element of the @tracking_information array is:
      # { type:     one of [ :queue, :work, :communication ]
      #   at:       begin time
      #   duration: duration
      #   vm:       vm (optional)
      # }
    end

    def queuing_completed(start, duration)
      @tracking_information << {
        type:     :queue,
        at:       start,
        duration: duration,
        # vm:
      }
    end

    def step_completed(start, duration)
      @tracking_information << {
        type:     :work,
        at:       start,
        duration: duration,
        # vm:
      }
      @step += 1
    end

    def finished_processing(time)
      # consider final communication latency
      @tracking_information << {
        type:     :communication,
        at:       time,
        duration: @communication_latency,
      }
      # save closure time
      @closure_time = time + @communication_latency
    end

    def next_step
      @step
    end

    def with_tracking_information(type=:all)
      selected_ti = if type == :all
        @tracking_information
      else
        @tracking_information.select{|el| el.type == type }
      end

      selected_ti.each do |ti|
        yield ti
      end
    end

    def total_communication_time
      calculate_time(:communication)
    end

    def total_work_time
      calculate_time(:work)
    end

    def total_queue_time
      calculate_time(:queue)
    end

    def closed?
      !@closure_time.nil?
    end

    def ttr
      # if incident isn't closed yet, just return nil without raising an exception.
      @closure_time.nil? ? nil : (@closure_time - @arrival_time)
    end

    def to_s
      "rid: #{@rid}, generation_time: #{@generation_time}, data_center_id: #{@data_center_id}, arrival_time: #{@arrival_time}"
    end

    private

      def calculate_time(type)
        return 0 unless @tracking_information
        @tracking_information.inject(0) {|sum,x| sum += ((type == :all || type == x[:type]) ? x[:duration].to_i : 0) }
      end
  end

end
