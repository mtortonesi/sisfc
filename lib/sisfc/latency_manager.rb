require 'erv'

module SISFC
  class LatencyManager
    def initialize(latency_models)
      # here we build a (strictly upper triangular) matrix of random variables
      # that represent the communication latency models between the different
      # locations
      @latency_models_matrix = latency_models.map do |lms_conf|
        lms_conf.map do |rv_conf| 
          ERV::RandomVariable.new(rv_conf) 
        end
      end

      # should we turn @latency_models_matrix from a (strictly upper)
      # triangular to a full matrix, for convenience? probably not. it would
      # require more memory and: 1) ruby is ***very*** memory hungry already,
      # 2) ruby's performance is very sensitive to memory usage.

      # precalculate average latencies
      @average_latency_matrix = @latency_models_matrix.map do |lms|
        lms.map{|x| x.mean }
      end
    end

    def sample_latency_between(loc1, loc2)
      if loc1 == loc2
        0.0 # this case should never happen, but you never know
      else
        l1, l2 = loc1 < loc2 ? [ loc1, loc2 ] : [ loc2, loc1 ]

        # since we use a compact representation for @latency_models_matrix, the
        # indexes become l1 and (l2-l1-1)
        @latency_models_matrix[l1][l2-l1-1].next
      end
    end

    def average_latency_between(loc1, loc2)
      if loc1 == loc2
        0.0 # this case should never happen, but you never know
      else
        l1, l2 = loc1 < loc2 ? [ loc1, loc2 ] : [ loc2, loc1 ]

        # since we use a compact representation for @average_latency_between, the
        # indexes become l1 and (l2-l1-1)
        @average_latency_between[l1][l2-l1-1]
      end
    end
  end
end
