require 'rspec'

$LOAD_PATH.unshift('app')
RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end

require 'cloud_controller/opi/apps_client'
require 'spec_helper'

# This spec requires the OPI binary to be in $PATH
RSpec.describe(OPI::Client) do
  let(:opi_url) { 'http://localhost:8085' }
  subject(:client) { described_class.new(opi_url) }
  let(:process) { double(guid: 'jeff') }

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
    context 'Desire ab app' do
      let(:lrp) {
        double(
          guid: 'guid_1234',
          name: 'jeff',
          version: '0.1.0',
          current_droplet: double(docker_receipt_image: 'http://example.org/image1234', droplet_hash: 'd_haash'),
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
  end
end