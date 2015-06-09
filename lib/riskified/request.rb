module Riskified
  class Request
    class << self
      # Assign the API path for the request
      # eg: endpoint_path 'api/create'
      #
      def endpoint_path(path = nil)
        if path
          @endpoint_path = path
        end

        @endpoint_path
      end
    end

    def endpoint_path
      self.class.endpoint_path
    end

    def post?
      true
    end
  end
end
