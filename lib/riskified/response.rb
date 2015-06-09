module Riskified
  class Response
    attr_reader :status_code
    attr_reader :data

    def initialize(status_code:, data:)
      @status_code = status_code
      @data = data
    end

    def success?
      status_code == 200
    end
  end
end
