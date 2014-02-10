require 'erv'

module SISFC
  class ServiceType
    attr_reader :level

    def initialize(opts)
      @level = opts[:level]
      @rv    = ERV::RandomVariable.new(opts[:service_time_distribution])
    end

    def get_random_service_time
      @rv.next
    end
  end
end
