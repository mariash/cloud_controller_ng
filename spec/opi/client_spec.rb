require 'cloud_controller/opi/client'
require 'webmock/rspec'

module VCAP
  module CloudController
    class AppModel; end
    class Config; end
  end
end

describe(OPI::Client) do
  describe 'can desire an app' do
    subject(:client) { described_class.new(opi_url) }
    let(:opi_url) { 'http://opi.service.cf.internal:8077' }
    let(:img_url) { 'http://example.org/image1234' }

    let(:lrp) {
      double(
        guid: 'guid_1234',
        name: 'dora',
        version: '0.1.0',
        current_droplet: double(docker_receipt_image: img_url, droplet_hash: 'd_haash'),
        command: 'ls -la',
        environment_json: { 'PORT': 8080, 'FOO': 'BAR' },
        desired_instances: 4,
        disk_quota: 100,
        memory: 256,
        file_descriptors: 0xBAAAAAAD,
        uris: [],
        space: double(
          name: 'name',
          guid: 'guid',
        ),
     )
    }

    let(:cfg) { double }

    context 'when request executes successfully' do
      before do
        stub_request(:put, "#{opi_url}/apps/guid_1234-0.1.0").to_return(status: 201)
        allow(VCAP::CloudController::Config).to receive(:config).and_return(cfg)
        allow(cfg).to receive(:get).with(:external_domain).and_return('api.example.com')
        allow(cfg).to receive(:get).with(:external_protocol).and_return('https')
      end

      it 'sends a PUT request' do
        response = client.desire_app(lrp)

        expect(response.status_code).to equal(201)
        expect(WebMock).to have_requested(:put, "#{opi_url}/apps/guid_1234-0.1.0").with(body: {
            process_guid: 'guid_1234-0.1.0',
            docker_image: img_url,
            start_command: 'ls -la',
            environment: [
              { name: 'PORT', value: '8080' },
              { name: 'FOO', value: 'BAR' },
              { name: 'VCAP_APPLICATION', value: {
                  cf_api: 'https://api.example.com',
                  limits: {
                    fds: 3131746989,
                    mem: 256,
                    disk: 100,
                  },
                  application_name: 'dora',
                  application_uris: [],
                  name: 'dora',
                  space_name: 'name',
                  space_id: 'guid',
                  uris: [],
                  users: nil,
                  application_id: 'guid_1234',
                  version: '0.1.0',
                  application_version: '0.1.0'
                }.to_json,
              },
            ],
            num_instances: 4,
            droplet_hash: 'd_haash'
          }.to_json
        )
      end
    end
  end

  describe 'can fetch scheduling infos' do
    let(:opi_url) { 'http://opi.service.cf.internal:8077' }

    let(:lrp) { double(lrps: [
      double(
        process_guid: 'guid_1234',
        imageUrl: 'http://example.org/image1234',
        command: ['ls', ' -la'],
        env: {
         'PORT' => 234,
         'FOO' => 'BAR'
       },
        targetInstances: 4
      ),
      double(
        process_guid: 'guid_5678',
        imageUrl: 'http://example.org/image5678',
        command: ['rm', '-rf', '/'],
        env: {
          'BAZ' => 'BAR'
        },
        targetInstances: 2
      )
    ])
    }

    let(:expected_body) { { lrps: [
      {
        process_guid: 'guid_1234',
        imageUrl: 'http://example.org/image1234',
        command: ['ls', ' -la'],
        env: {
          'PORT' => 234,
          'FOO' => 'BAR'
        },
        targetInstances: 4
      },
      {
        process_guid: 'guid_5678',

        imageUrl: 'http://example.org/image5678',
        command: ['rm', '-rf', '/'],
        env: {
          'BAZ' => 'BAR'
        },
        targetInstances: 2
      }
    ] }.to_json
    }

    subject(:client) {
      described_class.new(opi_url)
    }

    context 'when request executes successfully' do
      before do
        stub_request(:get, "#{opi_url}/apps").
          to_return(status: 200, body: expected_body)
      end

      it 'propagates the response' do
        response = client.fetch_scheduling_infos
        expect(WebMock).to have_requested(:get, "#{opi_url}/apps")
        expect(response.body).to eq(expected_body)
        expect(response.status_code).to eq(200)
      end
    end
  end
end
