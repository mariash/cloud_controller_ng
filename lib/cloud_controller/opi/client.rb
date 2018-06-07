require 'uri'
require 'httpclient'
require 'multi_json'
require 'json'
require 'ostruct'

module OPI
  class Client
    def initialize(opi_url)
      @opi_url = URI(opi_url)
    end

    def desire_app(process)
      client = HTTPClient.new
      @opi_url.path = "/apps/#{process.process_guid}"
      body = {
            process_guid: process.process_guid,
            docker_image: process.current_droplet.docker_receipt_image,
            start_command: process.command,
            env: convert(process.environment_json),
            num_instances: process.desired_instances,
            droplet_hash: process.current_droplet.droplet_hash
        }
      client.put(@opi_url, body: MultiJson.dump(body))
    end

    def convert(hash)
      hash.map do |k, v|
        { 'name' => k.to_s, 'value' => v.to_s }
      end
    end

    def fetch_scheduling_infos
      client = HTTPClient.new
      @opi_url.path = '/apps'

      resp = client.get(@opi_url)
      resp_json = JSON.parse(resp.body, object_class: OpenStruct)
      resp_json.desired_lrp_scheduling_infos
    end

    # We need these methods to exists in order to run our tests.
    def update_app(process_guid, lrp_updat); end

    def get_app(process_guid)
      ::Diego::Bbs::Models::DesiredLRP.new(
        process_guid: process_guid,
        routes: [],
      )
    end

    def stop_app(process_guid); end

    def bump_freshness
    end
  end
end
