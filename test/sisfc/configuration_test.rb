require 'stringio'
require 'tempfile'

require 'test_helper'


describe SISFC::Configuration do

  MINIMUM_VALID_CONFIG=<<-END
    start_time Time.utc(1978, 'Aug', 12, 14, 30, 0)
    warmup_duration 1.hour
    duration 6.months + 7.days
  END

  describe 'input source' do
    it 'should load from string' do
      SISFC::Configuration.load_from(MINIMUM_VALID_CONFIG)
    end

    it 'should load from file' do
      # create temporary file
      tf = Tempfile.open('MINIMUM_VALID_CONFIG')
      tf.write(MINIMUM_VALID_CONFIG)
      tf.close

      begin
        # create simulation
        SISFC::Configuration.load_from(tf.path)
      ensure
        # delete temporary file
        tf.delete
      end
    end

    it 'should load from StringIO' do
      SISFC::Configuration.load_from(StringIO.new(MINIMUM_VALID_CONFIG))
    end
  end


  describe 'simulation-related parameters' do

    it 'should correctly load simulation start' do
      conf = SISFC::Configuration.load_from(MINIMUM_VALID_CONFIG)
      conf.start_time.must_equal Time.utc(1978, 'Aug', 12, 14, 30, 0).to_f
    end

    it 'should correctly load simulation duration' do
      conf = SISFC::Configuration.load_from(MINIMUM_VALID_CONFIG)
      conf.duration.must_equal 6.months + 7.days
    end

    it 'should correctly load simulation duration' do
      conf = SISFC::Configuration.load_from(MINIMUM_VALID_CONFIG)
      conf.end_time.must_equal Time.utc(1978, 'Aug', 12, 14, 30, 0).to_f + 6.months + 7.days
    end

    it 'should correctly load warmup phase duration' do
      conf = SISFC::Configuration.load_from(MINIMUM_VALID_CONFIG)
      conf.warmup_duration.must_equal 1.hour
    end
  end


  # it "should initialize incident generation" do
  #   conf = nil

  #   MINIMUM_VALID_CONFIG = <<-END
  #     incident_generation :type => :random, :source => { :type => :exponential, :mean => 10.0 }
  #   END

  #   lambda {
  #     conf = SISFC::Configuration.load_from(MINIMUM_VALID_CONFIG)
  #   }.should_not raise_error

  #   conf.incident_generation.must_equal { :type => :random, :source => { :type => :exponential, :mean => 10.0 }}
  # end


  # it "should initialize support groups" do
  #   conf = nil

  #   MINIMUM_VALID_CONFIG = <<-END
  #     support_groups "SG1" => { :work_time => { :type => :exponential, :mean => 20 },
  #                               :operators => { :number => 3, :workshift => :all_day_long } }
  #   END

  #   conf = SISFC::Configuration.load_from(MINIMUM_VALID_CONFIG)

  #   conf.support_groups.must_equal { "SG1" => { :work_time => { :type => :exponential, :mean => 20 },
  #                                              :operators => { :number => 3, :workshift => :all_day_long } } }
  # end

end
