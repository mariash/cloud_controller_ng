require 'uri'
require 'httpclient'

module OPI
  class Client
    def initialize(opi_url)
      @opi_url = URI(opi_url)
    end

    def desire_lrp(lrp)
      client = HTTPClient.new
      @opi_url.path = "/apps/#{lrp.process_guid}"
      client.put(@opi_url,
        body: {
          imageUrl: lrp.image_url,
          command: lrp.command,
          env: lrp.env,
          targetInstances: lrp.target_instances
        }.to_json
        # TODO: Note that in the spike we had to use MultiJSON in order to get around a strange encoding issue
      )
    end

    def desired_lrps
      client = HTTPClient.new
      @opi_url.path = '/apps'

      client.get(@opi_url)
    end
  end
end
