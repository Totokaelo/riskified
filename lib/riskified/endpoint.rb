require 'openssl'
require 'curl'
require 'json'
require 'riskified/response'

module Riskified
  class Endpoint
    def initialize(endpoint_url:, auth_token:, shop_domain:)
      @endpoint_url = endpoint_url
      @auth_token = auth_token
      @shop_domain = shop_domain
    end

    # endpoint_path: eg 'api/create'
    # request_body: prebuilt json eg '{ order: { /* ... */ } }
    #
    def execute(endpoint_path, request_body)
      request_url = "#{@endpoint_url}/#{endpoint_path}"

      curl_response = Curl.post(request_url, request_body) do |http|
        standard_headers.each { |k,v| http.headers[k] = v }

        hashed_request_body = OpenSSL::HMAC.hexdigest('sha256', @auth_token, request_body)
        http.headers['X_RISKIFIED_HMAC_SHA256'] = hashed_request_body
      end

      riskified_response = Riskified::Response.new(
        status_code: curl_response.status.scan(/\d+/).first.to_i,
        data: JSON.parse(curl_response.body)
      )

      return riskified_response
    end


    # Creates a new checkout.
    # Should be called before attempting payment authorization and order creation.
    #
    def checkout_create(checkout)
      execute 'api/checkout_create',
        build_json(checkout)
    end

    # Alert that a checkout was denied authorization.
    #
    def checkout_denied(checkout_id, authorization_error)
      execute 'api/checkout_denied',
        build_json({
          id: checkout_id,
          authorization_error: authorization_error
        })
    end

    # Send a new order to Riskified.
    # Depending on your current plan, the newly created order might not be
    # submitted automatically for review.
    #
    def order_create(order)
      execute 'api/create',
        build_json(order)
    end

    # Submit a new or existing order to Riskified for review.
    # Forces the order to be submitted for review, regardless of your current plan.
    #
    def order_submit(order)
      execute 'api/submit',
        build_json(order)
    end

    # Update details of an existing order.
    # Orders are differentiated by their id field. To update an existing order, include its id
    # and any up-to-date data.
    #
    def order_update(order)
      execute 'api/update',
        build_json(order)
    end

    # Mark a previously submitted order as cancelled.
    # If the order has not yet been reviewed, it is excluded from future review.
    # If the order has already been reviewed and approved, cancelling it will also trigger a
    # full refund on any associated charges.
    # An order can only be cancelled during a relatively short time window after its creation.
    #
    def order_cancel(order_id, cancel_reason, cancelled_at)
      execute 'api/cancel',
        build_json({
          id: order_id,
          cancel_reason: cancel_reason,
          cancelled_at: cancelled_at.iso8601
        })
    end

    # Issue a partial refund for an existing order.
    # Any associated charges will be updated to reflect the new order total amount.
    #
    def order_partial_refund(order_id, refunds)
      execute 'api/refund',
        build_json({
          id: order_id,
          refunds: refunds
        })
    end

    # Notify that an existing order has completed fulfillment, covering both successful and failed attempts.
    # Include the tracking_company and tracking_numbers fields to eliminate delays during the chargeback reimbursement process.
    #
    def order_fulfill(order_id, fulfillments)
      execute 'api/fulfill',
        build_json({
          id: order_id,
          fulfillments: fulfillments
        })
    end

    # Update existing order external status.
    # Let us know what was your decision on your order.
    #
    def order_decision(order_id, decision_details)
      execute 'api/decision',
        build_json({
          id: order_id,
          decision: decision_details
        })
    end

    # Send an array (batch) of existing/historical orders to Riskified.
    # Orders sent will be used to build analysis models to better analyze newly received orders.
    #
    # Order data should be similar to the data sent to the /api/create endpoint and include
    # all available parameters of these orders (shipping/billing addresses, payment details, etc)
    #
    def historical(orders)
      execute 'api/historical',
        build_json({ orders: orders })
    end

    private

    def standard_headers
      {
        'ACCEPT' => "application/vnd.riskified.com; version=#{Riskified::API_VERSION}",
        'Content-Type' => 'application/json',
        'X_RISKIFIED_SHOP_DOMAIN' => @shop_domain
      }
    end

    def build_json(obj)
      obj.to_json
    end
  end
end
