# frozen_string_literal: true

require 'minitest_helper'

require_relative './reference_configuration'


describe SISFC::DataCenter do
  it 'should create a valid data center' do
    args = { maximum_vm_capacity: lambda {|vms| true } }
    dc = SISFC::DataCenter.new(id: :dc_name, location_id: 1, **args)
  end
end

