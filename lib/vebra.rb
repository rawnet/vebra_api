require "net/http"
require "uri"
require "json"
require "nokogiri"
require "vebra/api"
require "vebra/response"
require "vebra/client"
require "vebra/branch"
require "vebra/version"

module Vebra

end

module Net
  module HTTPHeader
    def basic_token(token)
      @header['authorization'] = [basic_encode_token(token)]
    end

    def basic_encode_token(token)
      'Basic ' + ["#{token}"].pack('m').delete("\r\n")
    end
    private :basic_encode_token
  end
end