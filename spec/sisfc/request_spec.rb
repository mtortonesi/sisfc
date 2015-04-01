require 'minitest/autorun'
require 'minitest/spec'

require 'sisfc'

require_relative './reference_configuration'


describe SISFC::Request do

  it 'should create a valid request' do
    r = SISFC::Request.new(rand(100),
                           (Time.now - 1.hour).to_f,
                           rand(10),
                           Time.now.to_f,
                           rand(4))
  end

end
