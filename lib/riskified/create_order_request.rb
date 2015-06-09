require 'riskified/request'

module Riskified
  class CreateOrderRequest < Request
    endpoint_path 'api/create'

    attr_accessor :order

    def data
      @order
    end
  end
end
