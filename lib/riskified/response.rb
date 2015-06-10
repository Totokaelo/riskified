module Riskified
  class Response
    attr_reader :status_code
    attr_reader :data
    attr_reader :message

    def initialize(status_code:, data: nil, message: nil)
      @status_code = status_code
      @message = message
      @data = data
    end

    def success?
      status_code == 200
    end
  end
end
