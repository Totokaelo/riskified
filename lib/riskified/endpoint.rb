require 'openssl'
require 'curl'

module Riskified
  class Endpoint
    def initialize(endpoint_url:, auth_token:, shop_domain:)
      @endpoint_url = endpoint_url
      @auth_token = auth_token
      @shop_domain = shop_domain
    end

    def execute(request)
      request_url = "#{@endpoint_url}/#{request.endpoint_path}"

      request_body = File.read('riskified_example_order.json')

      Curl.post(request_url, request_body) do |http|
        standard_headers.each { |k,v| http.headers[k] = v }

        hashed_request_body = OpenSSL::HMAC.hexdigest('sha256', @auth_token, request_body)
        http.headers['X_RISKIFIED_HMAC_SHA256'] = hashed_request_body
      end
    end

    private

    def standard_headers
      {
        'ACCEPT' => "application/vnd.riskified.com; version=#{Riskified::API_VERSION}",
        'Content-Type' => 'application/json',
        'X_RISKIFIED_SHOP_DOMAIN' => @shop_domain
      }
    end
  end
end
