require 'json'
require 'ostruct'
require 'httpclient'

class Hash
  def to_o
    JSON.parse to_json, object_class: OpenStruct
  end
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
        environment_variables = JSON.parse(lrp.environment_variables)
        body = {
          name: lrp.name,
          image: lrp.docker_image,
          command: Array(lrp.command),
          env: environment_variables,
          targetInstances: 1
        }

        response = @client.post("http://replace-me.com/v1/lrp", body)
        @logger.info(response)
      end
      
      def fetch_scheduling_infos
        response = @client.get("http://replace-me.com/v1/lrps")
        @logger.info(response)
        infos = JSON.parse(response.body)
        infos.to_o.desired_lrp_scheduling_infos
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
