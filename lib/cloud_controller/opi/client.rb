require 'uri'
require 'httpclient'
require 'multi_json'
require_relative '../../vcap/vars_builder'
require 'json'
require 'ostruct'

module OPI
  class Client
    def initialize(opi_url)
      @opi_url = URI(opi_url)
    end

    def desire_app(process)
      client = HTTPClient.new
      process_guid = process_guid(process)
      @opi_url.path = "/apps/#{process_guid}"
      client.put(@opi_url, body: desire_body(process))
    end

    def desire_body(process)
      body = {
        process_guid: process_guid(process),
        docker_image: process.current_droplet.docker_receipt_image,
        start_command: process.command.nil? ? process.detected_start_command : process.command,
        environment: convert_to_name_value_pair(vcap_application(process)),
        num_instances: process.desired_instances,
        droplet_hash: process.current_droplet.droplet_hash,
        last_updated: process.updated_at.to_f.to_s
      }
      MultiJson.dump(body)
    end

    def vcap_application(process)
      process.environment_json.merge(VCAP_APPLICATION: VCAP::VarsBuilder.new(process).to_hash)
    end

    def process_guid(process)
      "#{process.guid}-#{process.version}"
    end

    def fetch_scheduling_infos
      client = HTTPClient.new
      @opi_url.path = '/apps'

      resp = client.get(@opi_url)
      resp_json = JSON.parse(resp.body)
      resp_json["desired_lrp_scheduling_infos"].map { |h| to_recursive_ostruct(h) }
    end

    def update_app(process, _)
      client = HTTPClient.new
      @opi_url.path = "/apps/#{process.guid}"

      response = client.post(@opi_url, body: update_body(process))
      if response.status_code != 200
        response_json = recursive_ostruct(JSON.parse(response.body))
        raise CloudController::Errors::ApiError.new_from_details('RunnerError', response_json.error.message)
      end
      response
    end

    def update_body(process)
      body = {
        process_guid: process.guid,
        update: {
          instances: process.desired_instances,
          annotation: process.updated_at.to_f.to_s
        }
      }
      MultiJson.dump(body)
    end

    def recursive_ostruct(hash)
      OpenStruct.new(hash.map { |key, value|
        new_val = value.is_a?(Hash) ? recursive_ostruct(value) : value
        [key, new_val]
      }.to_h)
    end

    def get_app(process)
      client = HTTPClient.new
      @opi_url.path = "/app/#{process.guid}"

      response = client.get(@opi_url)
      if response.status_code == 404
        return nil
      end

      desired_lrp_response = recursive_ostruct(JSON.parse(response.body))
      desired_lrp_response.desired_lrp
    end

    def stop_app(process_guid); end

    def bump_freshness; end

    private

    def to_recursive_ostruct(hash)
      OpenStruct.new(hash.map { |key, value|
        new_val = value.is_a?(Hash) ? to_recursive_ostruct(value) : value
        [key, new_val]
      }.to_h)
    end

    def logger
      @logger ||= Steno.logger('cc.opi.apps_client')
    end

    def convert_to_name_value_pair(hash)
      hash.map do |k, v|
        case v
        when Array, Hash
          v = MultiJson.dump(v)
        else
          v = v.to_s
        end

        { name: k.to_s, value: v }
      end
    end
  end
end
