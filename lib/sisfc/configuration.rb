require 'sisfc/support/dsl_helper'


module ERV
  module GaussianMixtureHelper
    def self.RawParametersToMixtureArgs(*args)
      raise ArgumentError, "Arguments must be a multiple of 3!" if (args.count % 3) != 0
      args.each_slice(3).map do |(a,b,c)|
        { distribution: :gaussian, weight: a * c, args: { mean: b, sd: c } }
      end
    end
  end
end

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
    include ERV::GaussianMixtureHelper

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

      # TODO: might want to restrict this substitution only to the :filename
      # and :command keys
      @request_generation.each do |k,v|
        v.gsub!('<pwd>', File.expand_path(File.dirname(@filename)))
      end
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
