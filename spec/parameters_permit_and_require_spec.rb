require 'spec_helper'

describe Sinatra::StrongParameters do
  before do
    mock_app do
      set :raise_unpermitted, true
      helpers Sinatra::StrongParameters
  
      get '/root' do
        strong_params.permit(:foo)
        200
      end

      get '/nested' do
        strong_params.require(:foo).permit(:bar, :baz)
        200
      end
    end
  end

  context "required parameters" do
    it "raises MissingParameterError when parameter is missing" do
      expect { get "/nested" }.to raise_error(Sinatra::StrongParameters::ParameterMissing)
    end

    it "doesn't raise errors when required parameter is present" do
      get "/nested", foo: { bar: :bar }
      expect(last_response).to be_ok
    end
  end

  context "permitted parameters" do

    it "doesn't allow unpermitted parameters through" do
      expect { get "/root", { bar: 'bar' } }.to raise_error(Sinatra::StrongParameters::UnpermittedParameters)
    end

    it "allows permitted parameters through" do
      get "/root", { foo: 'foo' }
      expect(last_response).to be_ok 
    end
  end

  context "parameters as arrays" do
    it "allows parameters as arrays" do
      get "/root", { foo: ['foo1', 'foo2', 'foo3'] }
      expect(last_response).to be_ok
    end
  end

end
