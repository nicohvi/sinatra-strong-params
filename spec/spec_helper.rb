ENV['RACK_ENV'] = 'test'
require 'sinatra/strong_parameters'
require 'sinatra/test_helpers'
require 'byebug'

RSpec.configure do |config|
    config.include Sinatra::TestHelpers
end
