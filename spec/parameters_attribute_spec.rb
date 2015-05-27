require 'spec_helper'

describe Sinatra::StrongParameters do
  let(:params) { Sinatra::StrongParameters::Parameters.new(
    id: '1234', 
    injected: 'injected', 
    model: { key: 'value', sub_model: { sub_key: 'sub_value' } }) 
  }

  it "sets the hash as empty when nothing is permitted" do
    permitted = params.permit
    expect(permitted.empty?)
  end

  it "sets the permitted parameters" do
    permitted = params.permit(:id)
    expect(permitted[:id]).to eq('1234') 
  end

  it "doesn't set unpermitted parameters" do
    permitted = params.permit
    expect(permitted[:id]).to be_nil
    expect(permitted.length).to eq(0)
  end

  context "nested parameters" do
    it "sets nested parameters" do
      permitted = params.permit(:id, model: [:key, :other_key])
      expect(permitted[:model]).to_not be_nil
      expect(permitted[:model][:key]).to eq('value')
    end

    it "doesn't set nested unpermitted parameters" do
      permitted = params.permit(:id, model: [:key, :other_key])
      expect(permitted[:model][:other_key]).to be_nil 
    end

    it "sets deeply nested parameters" do
      permitted = params.permit(:id, model: [:key, sub_model: [:sub_key]])
      expect(permitted[:model][:sub_model]).to_not be_nil
      expect(permitted[:model][:sub_model][:sub_key]).to eq('sub_value')
    end

    it "allows empty arrays when permitted" do
      permitted = params.permit(model: [])
      expect(permitted[:model][:key]).to eq('value')
    end

    it "permits empty arrays for nested parameters" do
      permitted = params.permit(model: [sub_model: []]) 
      expect(permitted[:model][:sub_model][:sub_key]).to eq('sub_value')
    end
  end

  context "indifferent access" do
    it "parameters are permitted using both strings and symbols" do
      permitted = params.permit(model: [ { 'sub_model' => [:sub_key] }])
      expect(permitted[:model][:sub_model][:sub_key]).to eq('sub_value')
      
      permitted = params.permit(model: [ { :sub_model => [:sub_key] }])
      expect(permitted[:model][:sub_model][:sub_key]).to eq('sub_value')
    end
  end

  context "nested arrays with strings" do
    let(:params) { ActionController::Parameters.new({
      :book => {
        :title => "Romeo and Juliet",
        :author => "William Shakespeare"
      },
      :magazine => "Shakespeare Today"
    }) 
    }

  end

end
