require 'cloud_controller/opi/client'
require 'webmock/rspec'

module OPI
  RSpec.describe Client do
    subject(:client) {
      Client.new('http://opi.service.cf.internal:8077/')
    }
    let(:img_url) { 'http://example.org/image1234' }
    let(:lrp) {
      double(
        process_guid: 'guid_1234',
        image_url: img_url,
        command: ['ls', '-la'],
        env: {
          'PORT' => '8080',
          'FOO' => 'BAR'
        },
        target_instances: 4
     )
    }

    before do
      stub_request(:put, 'http://opi.service.cf.internal:8077/apps/guid_1234')
    end

    it 'sends a PUT request' do
      client.desire_lrp(lrp)

      expect(WebMock).to have_requested(:put, 'http://opi.service.cf.internal:8077/apps/guid_1234').
        with(body: {
          imageUrl: img_url,
          command: ['ls', '-la'],
          env: {
            'PORT' => '8080',
            'FOO' => 'BAR'
          },
          targetInstances: 4
        }.to_json
      )
    end
  end
end
