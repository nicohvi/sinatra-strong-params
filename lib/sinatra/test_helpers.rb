require 'sinatra/base'
require 'rack/test'

module Sinatra
  Base.set :environment, :test

  module TestHelpers
    include Rack::Test::Methods

    def mock_app(base = Sinatra::Base, &block)
      @app = Sinatra.new(base) do
        inner = self
        class_eval(&block)
      end
      app
    end

    def app=(base)
      @app = base
    end

    def app
      @app ||= Class.new Sinatra::Base
    end

  end
end
