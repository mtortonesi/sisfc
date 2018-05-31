# frozen_string_literal: true

require 'sisfc/request'

module SISFC
  class Statistics
    attr_reader :mean, :n

    # see http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#Online_algorithm
    def initialize
      @n    = 0 # number of requests
      @mean = 0.0
      @m_2  = 0.0
    end

    def record_request(req)
      # get new sample
      x = req.ttr

      # update counters
      @n += 1
      delta = x - @mean
      @mean += delta / @n
      @m_2  += delta * (x - @mean)
    end

    def variance
      @m_2 / (@n - 1)
    end
  end
end
