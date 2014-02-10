require 'sisfc/support/dsl_helper'

module SISFC

  class Configuration

    dsl_accessor :start_time,
                 :duration,
                 :warmup_duration,
                 :request_generation,
                 :data_centers,
                 :service_component_types,
                 :evaluation,
                 :workflow_types

    def end_time
      @start_time + @duration
    end

    def validate
      # convert datetimes and integers into floats
      @start_time      = @start_time.to_f
      @duration        = @duration.to_f
      @warmup_duration = @warmup_duration.to_f
    end

    def self.load_from(input)
      # allow filename, string, and IO objects as input
      if input.kind_of?(String)
        if File.exists?(input)
          input = File.new(input, 'r')
        else
          input = StringIO.new(input)
        end
      else
        raise RuntimeError unless input.respond_to?(:read)
      end

      # create configuration object
      conf = Configuration.new

      # take the input source contents and pass them to instance_eval
      conf.instance_eval(input.read)

      # validate and finalize configuration
      conf.validate

      # return new object
      conf
    end

  end
end
