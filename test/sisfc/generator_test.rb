require 'tempfile'

require 'test_helper'
require 'sisfc/generator'


describe SISFC::RequestGenerator do

  GENERATION_TIMES = [ Time.now, Time.now + 1.second, Time.now + 2.seconds ].map(&:to_f)
  DATA_CENTER_IDS = [ 1, 2, 3 ]
  ARRIVAL_TIMES = GENERATION_TIMES.map {|x| x + 1.0 }
  CONTENT=<<-END
    Generation Time,Data Center ID,Arrival Time
    #{GENERATION_TIMES[0]},#{DATA_CENTER_IDS[0]},#{ARRIVAL_TIMES[0]}
    #{GENERATION_TIMES[1]},#{DATA_CENTER_IDS[1]},#{ARRIVAL_TIMES[1]}
    #{GENERATION_TIMES[2]},#{DATA_CENTER_IDS[2]},#{ARRIVAL_TIMES[2]}
  END

  it 'should read from CSV file' do
    tf = Tempfile.new('generator_test')
    tf.write(CONTENT)
    tf.close

    begin
      rg = SISFC::RequestGenerator.new(filename: tf.path)
      r = rg.generate
      r.rid.must_equal 1
      r.generation_time.must_equal GENERATION_TIMES[0]
      r.data_center_id.must_equal DATA_CENTER_IDS[0]
      r.arrival_time.must_equal ARRIVAL_TIMES[0]
    ensure
      # delete temporary file
      tf.delete
    end
  end

  it 'should read from command' do
    tf = Tempfile.new('generator_test')
    tf.write(CONTENT)
    tf.close

    begin
      rg = SISFC::RequestGenerator.new(command: "cat #{tf.path}")
      r = rg.generate
      r.rid.must_equal 1
      r.generation_time.must_equal GENERATION_TIMES[0]
      r.data_center_id.must_equal DATA_CENTER_IDS[0]
      r.arrival_time.must_equal ARRIVAL_TIMES[0]
    ensure
      # delete temporary file
      tf.delete
    end
    
  end

end
