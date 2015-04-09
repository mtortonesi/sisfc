require 'minitest_helper'

require 'tempfile'
require 'sisfc/generator'

require_relative './reference_configuration'


describe SISFC::RequestGenerator do

  GENERATION_TIMES = [ Time.now, Time.now + 1.second, Time.now + 2.seconds ].map(&:to_f)
  DATA_CENTER_IDS  = (1..GENERATION_TIMES.size).to_a
  ARRIVAL_TIMES    = GENERATION_TIMES.map {|x| x + 1.0 }
  WORKFLOW_IDS     = GENERATION_TIMES.map { rand(10) }
  REQUEST_GENERATION_DATA=<<-END
    Generation Time,Data Center ID,Arrival Time,Workflow ID
    #{GENERATION_TIMES[0]},#{DATA_CENTER_IDS[0]},#{ARRIVAL_TIMES[0]},#{WORKFLOW_IDS[0]}
    #{GENERATION_TIMES[1]},#{DATA_CENTER_IDS[1]},#{ARRIVAL_TIMES[1]},#{WORKFLOW_IDS[1]}
    #{GENERATION_TIMES[2]},#{DATA_CENTER_IDS[2]},#{ARRIVAL_TIMES[2]},#{WORKFLOW_IDS[2]}
  END

  it 'should read from CSV file' do
    begin
      # create temporary file with request generation information
      tf = Tempfile.new('generator_test')
      tf.write(REQUEST_GENERATION_DATA)
      tf.close

      with_reference_config(request_generation: { filename: tf.path }) do |conf|
        rg = SISFC::RequestGenerator.new(conf.request_generation)
        r = rg.generate
        r.rid.must_equal 1
        r.generation_time.must_equal GENERATION_TIMES[0]
        r.data_center_id.must_equal DATA_CENTER_IDS[0]
        r.arrival_time.must_equal ARRIVAL_TIMES[0]
      end

    ensure
      # delete temporary file
      tf.delete
    end
  end

  it 'should read from command' do
    begin
      # create temporary file with request generation information
      tf = Tempfile.new('generator_test')
      tf.write(REQUEST_GENERATION_DATA)
      tf.close

      with_reference_config(request_generation: { command: "cat #{tf.path}" }) do |conf|
        rg = SISFC::RequestGenerator.new(conf.request_generation)
        r = rg.generate
        r.rid.must_equal 1
        r.generation_time.must_equal GENERATION_TIMES[0]
        r.data_center_id.must_equal DATA_CENTER_IDS[0]
        r.arrival_time.must_equal ARRIVAL_TIMES[0]
      end
    ensure
      # delete temporary file
      tf.delete
    end
  end

end
