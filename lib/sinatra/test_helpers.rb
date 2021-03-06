require 'sinatra/base'
require 'rack/test'

module Sinatra
  Base.set :environment, :test

  module TestHelpers
    include Rack::Test::Methods

    def mock_app(base = Sinatra::Base, &block)
      @app = Sinatra.new(base) do
        class_eval(&block)
      end
      app
    end

    def app=(base)
      @app = base
    end

    def app
      @app ||= Sinatra::Base.new
    end

  end
end
