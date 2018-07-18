# frozen_string_literal: true

require 'minitest_helper'

require_relative './reference_configuration'


describe SISFC::DataCenter do
  it 'should create a valid public Cloud data center' do
    args = { maximum_vm_capacity: lambda {|vms| true } }
    dc = SISFC::DataCenter.new(id: :dc_name, name: "Some DC", type: :public, location_id: 1, **args)
  end

  it 'should create a valid private Cloud data center' do
    args = { maximum_vm_capacity: lambda {|vms| true } }
    dc = SISFC::DataCenter.new(id: :dc_name, name: "Some DC", type: :private, location_id: 1, **args)
  end
end

