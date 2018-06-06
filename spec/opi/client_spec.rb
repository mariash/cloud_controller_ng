require 'cloud_controller/opi/client'
require 'webmock/rspec'

module OPI
  RSpec.describe Client do
    describe '#desire_app' do
      let(:opi_url) { 'http://opi.service.cf.internal:8077' }
      subject(:client) {
        Client.new(opi_url)
      }
      let(:img_url) { 'http://example.org/image1234' }
      let(:lrp) {
        double(
          process_guid: 'guid_1234',
          version: '0.1.0',
          current_droplet: double(docker_receipt_image: img_url, droplet_hash: 'd_haash'),
          command: 'ls -la',
          environment_json: { 'PORT': 8080, 'FOO': 'BAR' },
          desired_instances: 4
       )
      }

      context 'when request executes successfully' do
        before do
          stub_request(:put, "#{opi_url}/apps/guid_1234").
            to_return(status: 201)
        end
        it 'sends a PUT request' do
          response = client.desire_app(lrp)

          expect(response.status_code).to equal(201)
          expect(WebMock).to have_requested(:put, "#{opi_url}/apps/guid_1234").
            with(body: MultiJson.dump({
              process_guid: 'guid_1234',
              docker_image: img_url,
              start_command: 'ls -la',
              env: [{ name: 'PORT', value: '8080' }, { name: 'FOO', value: 'BAR' }],
              num_instances: 4,
              droplet_hash: 'd_haash'
            }
          ))
        end
      end
    end
    describe '#fetch_scheduling_infos' do
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
        Client.new(opi_url)
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
end
