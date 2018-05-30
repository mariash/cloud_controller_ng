require 'json'
require 'multi_json'
require 'ostruct'
require 'httpclient'

def to_recursive_ostruct(hash)
  OpenStruct.new(hash.each_with_object({}) do |(key, val), memo|
    memo[key] = val.is_a?(Hash) ? to_recursive_ostruct(val) : val
  end)
end

module VCAP::CloudController
  module OPI
    class AppsClient

      def initialize()
        @client = HTTPClient.new
        @logger = Steno.logger('cc.opi.apps_client')
      end

      def desire_app(lrp)
        @logger.info("Desiring lrp ", lrp)
        raw_body = Diego::Protocol.new.desire_app_message(lrp, 60)
        body = MultiJson.dump(raw_body)
        response = @client.post("http://cube.service.cf.internal:8076/v1/lrp", body)
        @logger.info(response)
      end

      def fetch_scheduling_infos
        response = @client.get("http://cube.service.cf.internal:8076/v1/lrps")
        info_hash = JSON.parse(response.body)
        info_obj = OpenStruct.new(info_hash)
        infos = info_obj.desired_lrp_scheduling_infos.map { |d| to_recursive_ostruct(d) }
        @logger.info(infos)
        infos
      end

      def update_app(process_guid, lrp_update) #this should be a no-op
      end

      def get_app(process_guid) #this one should return something that satisfies the DesireAppHandler useage of get_app
        @logger.info("Returning stubbed app for process #{process_guid}")
        ::Diego::Bbs::Models::DesiredLRP.new(
          process_guid: process_guid,
          routes: [],
        )
      end

      def stop_app(process_guid) # this too should be a no-op
        @logger.info("Calling stubbed stop app for #{process_guid}")
      end

      def bump_freshness
        @logger.info("Bumping freshness")
      end

    end
  end
end
