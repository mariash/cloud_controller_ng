require 'spec_helper'
require 'cloud_controller/opi/client'
require 'webmock/rspec'

module OPI
  RSpec.describe Client do
    subject(:client){Client.new}
    
    before do
      stub_request(:put, "http://eirini.service.cf.internal:8076/lrp")
    end

    it 'sends a PUT request' do
      client.desire_lrp
      expect(WebMock).to have_requested(:put, "http://eirini.service.cf.internal:8076/lrp")
    end
  end 
end
