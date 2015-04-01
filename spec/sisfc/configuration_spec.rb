require 'minitest/autorun'
require 'minitest/spec'

require 'sisfc'

require_relative './reference_configuration'


describe SISFC::Configuration do

  describe 'simulation-related parameters' do

    it 'should correctly load simulation start' do
      with_reference_config do |conf|
        conf.start_time.must_equal START_TIME
      end
    end

    it 'should correctly load simulation duration' do
      with_reference_config do |conf|
        conf.duration.must_equal DURATION
      end
    end

    it 'should correctly load simulation end time' do
      with_reference_config do |conf|
        conf.end_time.must_equal START_TIME + DURATION
      end
    end

    it 'should correctly load warmup phase duration' do
      with_reference_config do |conf|
        conf.warmup_duration.must_equal WARMUP_DURATION
      end
    end

  end


  describe 'service_component_types' do

    it 'should have 3 items' do
      with_reference_config do |conf|
        conf.service_component_types.size.must_equal 3
      end
    end

    it 'should define a Web Server' do
      with_reference_config do |conf|
        conf.service_component_types.keys.must_include('Web Server')
      end
    end

    it 'should define an App Server' do
      with_reference_config do |conf|
        conf.service_component_types.keys.must_include('App Server')
      end
    end

    it 'should define a Financial Transaction Server' do
      with_reference_config do |conf|
        conf.service_component_types.keys.must_include('Financial Transaction Server')
      end
    end

    describe 'the Web Server' do
      it 'should work on medium or large VMs' do
        with_reference_config do |conf|
          item_conf = conf.service_component_types['Web Server']
          item_conf[:allowed_vm_types].must_include(:medium)
          item_conf[:allowed_vm_types].must_include(:large)
        end
      end
    end

    describe 'the App Server' do
      it 'should work on large and huge VMs' do
        with_reference_config do |conf|
          item_conf = conf.service_component_types['App Server']
          item_conf[:allowed_vm_types].must_include(:large)
          item_conf[:allowed_vm_types].must_include(:huge)
        end
      end
    end

  end


  describe 'data_centers' do
    it 'should have 5 items' do
      with_reference_config do |conf|
        conf.data_centers.size.must_equal 5
      end
    end
  end

end
