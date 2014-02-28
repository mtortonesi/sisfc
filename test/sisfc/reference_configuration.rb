require 'sisfc/configuration'

START_TIME      = Time.utc(1978, 'Aug', 12, 14, 30, 0).to_f
DURATION        = 1.minute.to_f
WARMUP_DURATION = 10.seconds.to_f
SIMULATION_CHARACTERIZATION = <<END
  # start time, duration, and warmup time for simulations
  start_time Time.utc(1978, 'Aug', 12, 14, 30, 0)
  duration 1.minute
  warmup_duration 10.seconds
END


# characterization of data centers
DATA_CENTERS_CHARACTERIZATION = <<END
data_centers \
  1 => {
    :maximum_vm_capacity => {
      :tiny   => 300,
      :small  => 300,
      :medium => 300,
      :large  => 300,
      :huge   => 300,
    },
  },
  2 => {
    :maximum_vm_capacity => {
      :tiny   => 300,
      :small  => 300,
      :medium => 300,
      :large  => 300,
      :huge   => 300,
    },
  },
  3 => {
    :maximum_vm_capacity => {
      :tiny   => 300,
      :small  => 300,
      :medium => 300,
      :large  => 300,
      :huge   => 300,
    },
  },
  4 => {
    :maximum_vm_capacity => {
      :tiny   => 300,
      :small  => 300,
      :medium => 300,
      :large  => 300,
      :huge   => 300,
    },
  },
  5 => {
    :maximum_vm_capacity => {
      :tiny   => 300,
      :small  => 300,
      :medium => 300,
      :large  => 300,
      :huge   => 300,
    },
  }
END


# characterization of component types
SERVICE_COMPONENT_TYPES_CHARACTERIZATION = <<END
service_component_types \
  'Web Server' => {
    :allowed_vm_types => [ :medium, :large ],
    :service_time_distribution => {
      :medium => { :distribution => :gaussian,
                   :mu           => 0.009, # 1 request processed every 9ms
                   :sigma        => 0.001 },
      :large  => { :distribution => :gaussian,
                   :mu           => 0.007, # 1 request processed every 7ms
                   :sigma        => 0.001 } },
    :estimated_workload => 50,
  },
  'App Server' => {
    :allowed_vm_types => [ :medium, :large, :huge ],
    :service_time_distribution => {
      :medium => { :distribution => :gaussian,
                   :mu           => 0.015, # 1 request processed every 15ms
                   :sigma        => 0.005 },
      :large  => { :distribution => :gaussian,
                   :mu           => 0.012, # 1 request processed every 12ms
                   :sigma        => 0.003 },
      :huge   => { :distribution => :gaussian,
                   :mu           => 0.009, # 1 request processed every 7ms
                   :sigma        => 0.002 } },
    :estimated_workload => 70,
  },
  'Financial Transaction Server' => {
    :allowed_vm_types => [ :large, :huge ],
    :service_time_distribution => {
      :large  => { :distribution => :gaussian,
                   :mu           => 0.015, # 1 request processed every 15ms
                   :sigma        => 0.004 },
      :huge   => { :distribution => :gaussian,
                   :mu           => 0.008, # 1 request processed every 8ms
                   :sigma        => 0.003 } },
    :estimated_workload => 80,
  }
END


# workflow (or job) types descriptions
WORKFLOW_TYPES_CHARACTERIZATION = <<END
workflow_types \
  1 => {
    :component_sequence => [
      { :name => 'Web Server' }, # no need for :type => dedicated / shared
      { :name => 'App Server' },
      { :name => 'Financial Transaction Server' },
    ],
    :next_component_selection => :random,
  },
  2 => {
    :component_sequence => [
      { :name => 'Web Server' }, # no need for :type => dedicated / shared
      { :name => 'App Server' },
    ],
    # :next_component_selection => :least_loaded,
    :next_component_selection => :random,
  }
END


REQUEST_GENERATION_CHARACTERIZATION = <<END
request_generation \
  command: "<pwd>/generator.R"
END

EVALUATION_CHARACTERIZATION = <<END
evaluation \
  :vm_hourly_cost => [
    { :data_center => 1, :vm_type => :medium, :cost => 0.160 },
    { :data_center => 1, :vm_type => :large,  :cost => 0.320 },
    { :data_center => 2, :vm_type => :medium, :cost => 0.184 },
    { :data_center => 2, :vm_type => :large,  :cost => 0.368 }
  ],
  # 500$ penalties if MTTR takes more than 50 msecs
  :penalties => lambda {|kpis,dc_kpis| 500.0 if kpis[:mttr] > 0.050 }
END

# this is the whole reference configuration
# (useful for spec'ing configuration.rb)
REFERENCE_CONFIGURATION =
  SIMULATION_CHARACTERIZATION +
  DATA_CENTERS_CHARACTERIZATION +
  SERVICE_COMPONENT_TYPES_CHARACTERIZATION +
  WORKFLOW_TYPES_CHARACTERIZATION +
  REQUEST_GENERATION_CHARACTERIZATION +
  EVALUATION_CHARACTERIZATION


evaluator = Object.new
evaluator.extend SISFC::Configurable
evaluator.instance_eval(REFERENCE_CONFIGURATION)

# these are preprocessed portions of the reference configuration
# (useful for spec'ing everything else)
DATA_CENTERS            = evaluator.data_centers
SERVICE_COMPONENT_TYPES = evaluator.service_component_types
WORKFLOW_TYPES          = evaluator.workflow_types
EVALUATION              = evaluator.evaluation


def with_reference_config(opts={})
  begin
    # create temporary file with reference configuration
    tf = Tempfile.open('REFERENCE_CONFIGURATION')
    tf.write(REFERENCE_CONFIGURATION)
    tf.close

    # create a configuration object from the reference configuration file
    conf = SISFC::Configuration.load_from_file(tf.path)

    # apply any change from the opts parameter and validate the modified configuration
    opts.each do |k,v|
      conf.send(k, v)
    end
    conf.validate

    # pass the configuration object to the block
    yield conf
  ensure
    # delete temporary file
    tf.delete
  end
end
