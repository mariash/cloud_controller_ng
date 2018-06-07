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
      let(:expected_body) { { desired_lrp_scheduling_infos: [
        {
          desired_lrp_key: {
            process_guid: 'guid_1234'
          }
        },
        {
          desired_lrp_key: {
            process_guid: 'guid_5678'
          }
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
          scheduling_infos = client.fetch_scheduling_infos
          expect(WebMock).to have_requested(:get, "#{opi_url}/apps")

          expect(scheduling_infos.size).to eq(2)
          guids = scheduling_infos.map { |p| p.desired_lrp_key.process_guid }
          expect(guids).to match_array(["guid_1234", "guid_5678"])
        end
      end
    end
  end
end
