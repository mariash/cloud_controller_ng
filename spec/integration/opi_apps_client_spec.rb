require 'rspec'

$LOAD_PATH.unshift('app')

require 'cloud_controller/opi/apps_client'
require 'spec_helper'

# This spec requires the OPI binary to be in $PATH
RSpec.describe(OPI::Client) do
  let(:opi_url) { 'http://localhost:8085' }
  subject(:client) { described_class.new(opi_url) }
  let(:process) { double(guid: 'jeff',
                         desired_instances: 5,
                         updated_at: '1241232.42')
  }

  before :all do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  def up?(url)
    HTTPClient.new.get(url)
  rescue Errno::ECONNREFUSED
    yield if block_given?
    nil
  end

  before do
    @pid = Process.spawn('opi simulator')

    raise 'Boom' unless 5.times.any? { up?(opi_url) {
      sleep 0.1
    }}
  end

  after do
    Process.kill('SIGTERM', @pid)
  end

  context 'OPI system tests' do
    context 'Desire an app' do
      let(:lrp) {
        double(
          guid: 'guid_1234',
          name: 'jeff',
          version: '0.1.0',
          current_droplet: double(docker_receipt_image: 'http://example.org/image1234', droplet_hash: 'd_haash'),
          command: 'ls -la',
          environment_json: { 'PORT': 8080, 'FOO': 'BAR' },
          health_check_type: 'port',
          health_check_http_endpoint: '/healthz',
          health_check_timeout: 420,
          desired_instances: 4,
          disk_quota: 100,
          memory: 256,
          file_descriptors: 0xBAAAAAAD,
          uris: [],
          space: double(
            name: 'name',
            guid: 'guid',
          ),
          updated_at: Time.at(1529064800.9),
       )
      }
      it 'does not error' do
        expect { client.desire_app(lrp) }.to_not raise_error
      end
    end

    context 'Get an app' do
      it 'does not error' do
        WebMock.allow_net_connect!
        expect { client.get_app(process) }.to_not raise_error
      end

      it 'returns the correct process' do
        actual_process = client.get_app(process)
        expect(actual_process.process_guid).to eq('jeff')
      end
    end

    context 'Update an app' do
      before do
        routes = {
              'http_routes' => [
                {
                  'hostname'          => 'numero-uno.example.com',
                  'port'              => 8080
                },
                {
                  'hostname'          => 'numero-dos.example.com',
                  'port'              => 8080
                }
              ]
        }

        routing_info = instance_double(VCAP::CloudController::Diego::Protocol::RoutingInfo)
        allow(routing_info).to receive(:routing_info).and_return(routes)
        allow(VCAP::CloudController::Diego::Protocol::RoutingInfo).to receive(:new).with(process).and_return(routing_info)
      end

      it 'does not error' do
        WebMock.allow_net_connect!
        expect { client.update_app(process, {}) }.to_not raise_error
      end
    end
  end
end
