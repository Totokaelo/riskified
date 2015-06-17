module Riskified
  # Hashes some text according to Riskified's security scheme.
  #
  def self.hash(auth_token, text)
    OpenSSL::HMAC.hexdigest('sha256', auth_token, text)
  end
end
