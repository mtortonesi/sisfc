# frozen_string_literal: true

require 'minitest_helper'
require 'sisfc/latency_manager'

require_relative './reference_configuration'


describe SISFC::LatencyManager do
  it 'should correctly work with reference configuration' do
    SISFC::LatencyManager.new(LATENCY_MODELS)
  end
end
