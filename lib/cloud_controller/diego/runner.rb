module VCAP::CloudController
  module Diego
    class Runner
      class CannotCommunicateWithDiegoError < StandardError; end

      attr_writer :messenger

      def initialize(process, config)
        @process = process
        @config = config
      end

      def scale
        raise CloudController::Errors::ApiError.new_from_details('RunnerError', 'App not started') unless @process.started?

        # skip LRP request if pending to allow:
        # - scaling while a push is in-progress, sync job will eventually scale instances
        # - user specifies the instance count and the app stack in a PUT to update, subsequent `cf start` will submit LRP
        with_logging('scale') { messenger.send_desire_request(@process) } unless @process.pending?
      end

      def start(_={})
        with_logging('start') { messenger.send_desire_request(@process) }
      end

      def update_routes
        raise CloudController::Errors::ApiError.new_from_details('RunnerError', 'App not started') unless @process.started?
        with_logging('update_route') { messenger.send_desire_request(@process) unless @process.staging? }
      end

      def desire_app_message
        Diego::Protocol.new.desire_app_message(@process, @config.get(:default_health_check_timeout))
      end

      def stop
        with_logging('stop_app') { messenger.send_stop_app_request(@process) }
      end

      def stop_index(index)
        with_logging('stop_index') { messenger.send_stop_index_request(@process, index) }
      end

      def with_logging(action=nil)
        yield
      rescue StandardError => e
        return raise e unless diego_not_responding_error?(e)
        logger.error "Cannot communicate with diego - tried to send #{action}"
        raise CannotCommunicateWithDiegoError.new(e.message)
      end

      def messenger
        @messenger ||= Diego::Messenger.new
      end

      private

      def diego_not_responding_error?(e)
        /getaddrinfo/ =~ e.message
      end

      def logger
        @logger ||= Steno.logger('cc.diego.runner')
      end
    end
  end
end
