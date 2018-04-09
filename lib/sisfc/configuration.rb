require 'sisfc/support/dsl_helper'

require_relative './latency_manager'

module SISFC

  module Configurable
    dsl_accessor :constraints,
                 :customers,
                 :data_centers,
                 :duration,
                 :evaluation,
                 :kpi_customization,
                 :latency_models,
                 :request_generation,
                 :service_component_types,
                 :start_time,
                 :warmup_duration,
                 :workflow_types
  end

  class Configuration
    include Configurable

    attr_accessor :filename

    def initialize(filename)
      @filename = filename
    end

    def end_time
      @start_time + @duration
    end

    def validate
      # convert datetimes and integers into floats
      @start_time      = @start_time.to_f
      @duration        = @duration.to_f
      @warmup_duration = @warmup_duration.to_f

      # initialize kpi_customization to empty hash if needed
      @kpi_customization ||= {}

      # create latency manager
      @latency_manager = LatencyManager.new(@latency_models)

      # TODO: might want to restrict this substitution only to the :filename
      # and :command keys
      @request_generation.each do |k,v|
        v.gsub!('<pwd>', File.expand_path(File.dirname(@filename)))
      end
    end

    def communication_latency(loc1, loc2)
      @latency_manager.sample_latency_between(loc1.to_i, loc2.to_i)
    end

    def self.load_from_file(filename)
      # allow filename, string, and IO objects as input
      raise ArgumentError, "File #{filename} does not exist!" unless File.exists?(filename)

      # create configuration object
      conf = Configuration.new(filename)

      # take the file content and pass it to instance_eval
      conf.instance_eval(File.new(filename, 'r').read)

      # validate and finalize configuration
      conf.validate

      # return new object
      conf
    end

  end
end
