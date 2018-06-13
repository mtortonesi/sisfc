# frozen_string_literal: true

require_relative './logger'

module SISFC
  class Evaluator

    include Logging

    def initialize(conf)
      @vm_hourly_cost = conf.evaluation[:vm_hourly_cost]
      raise ArgumentError, 'No VM hourly costs provided!' unless @vm_hourly_cost

      @penalties_func = conf.evaluation[:penalties]
    end

    def evaluate_business_impact(all_kpis, per_workflow_and_customer_kpis,
                                 vm_allocation, data_center_repository)
      # evaluate VM daily costs
      cost = vm_allocation.inject(0.0) do |s,x|
        hc = @vm_hourly_cost.find{|i| i[:data_center] == x[:dc_id] and i[:vm_type] == x[:vm_size] }
        if hc
          s += x[:vm_num] * hc[:cost]
        else
          logger.warn("Cannot find hourly cost for data center #{x[:dc_id]} and VM size #{x[:vm_size]}!")
          s
        end
      end
      cost *= 24.0
      all_kpis[:cost] = cost
      # puts "vm allocation cost: #{cost}"

      # consider SLO violations
      penalties = (@penalties_func.nil? ? 0.0 : (@penalties_func.call(all_kpis, per_workflow_and_customer_kpis) or 0.0))
      all_kpis[:penalties] = penalties
      # puts "slo penalties cost: #{penalties}"
      cost += penalties

      # we want to minimize the cost, so we define fitness as -cost
      fitness = -cost
    end
  end
end

