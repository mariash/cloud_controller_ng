require 'httpclient'
require 'json'
require 'cloud_controller/errors/instances_unavailable'
require 'cloud_controller/errors/no_running_instances'

module OPI
  class InstancesClient
    ActualLRPKey = Struct.new(:index, :process_guid)

    class ActualLRP
      attr_reader :actual_lrp_key
      attr_reader :state
      attr_reader :since
      attr_reader :placement_error

      def initialize(actual_lrp_key, state)
        @actual_lrp_key = actual_lrp_key
        @state = state
        @since = 0
        @placement_error = ''
      end

      def ==(other)
        other.class == self.class && other.actual_lrp_key == @actual_lrp_key
      end
    end

    def initialize(opi_url)
      @client = HTTPClient.new(base_url: URI(opi_url))
    end

    def lrp_instances(process)
      path = "/apps/#{process.guid}/instances"
      begin
        retries ||= 0
        resp = @client.get(path)
        resp_json = JSON.parse(resp.body)
        handle_error(resp_json)
      rescue CloudController::Errors::NoRunningInstances => e
        retry if (retries += 1) < 5
        raise e
      end
      process_guid = resp_json['process_guid']
      resp_json['instances'].map do |instance|
        ActualLRP.new(ActualLRPKey.new(instance['index'], process_guid), instance['state'])
      end
    end

    def desired_lrp_instance(process); end

    private

    def handle_error(response_body)
      error = response_body['error']
      return unless error

      raise CloudController::Errors::NoRunningInstances.new('No running instances')
    end
  end
end
