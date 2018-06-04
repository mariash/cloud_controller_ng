require 'httpclient'

module OPI
  class Client
    def desire_lrp
      client = HTTPClient.new
      client.put("http://eirini.service.cf.internal:8076/lrp")
    end
  end
end

