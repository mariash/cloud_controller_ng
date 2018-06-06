require 'cloud_controller/opi/client'
require 'webmock/rspec'

module OPI
  RSpec.describe Client do
    describe '#desire_lrp' do
      let(:opi_url) { 'http://opi.service.cf.internal:8077' }
      subject(:client) {
        Client.new(opi_url)
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

      context 'when request executes successfully' do
        before do
          stub_request(:put, "#{opi_url}/apps/guid_1234").
            to_return(status: 201)
        end
        it 'sends a PUT request' do
          response = client.desire_lrp(lrp)

          expect(response.status_code).to equal(201)
          expect(WebMock).to have_requested(:put, "#{opi_url}/apps/guid_1234").
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
    describe '#get_lrps' do
      let(:opi_url) { 'http://opi.service.cf.internal:8077' }
      let(:lrp) { double(lrps: [
        double(
          imageUrl: 'http://example.org/image1234',
          command: ['ls', ' -la'],
          env: {
           'PORT' => 234,
           'FOO' => 'BAR'
         },
          targetInstances: 4
        ),
        double(
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
          imageUrl: 'http://example.org/image1234',
          command: ['ls', ' -la'],
          env: {
            'PORT' => 234,
            'FOO' => 'BAR'
          },
          targetInstances: 4
        },
        {
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
          response = client.desired_lrps
          expect(WebMock).to have_requested(:get, "#{opi_url}/apps")
          expect(response.body).to eq(expected_body)

          expect(response.status_code).to eq(200)
        end
      end
    end
  end
end
