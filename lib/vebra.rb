require "net/http"
require "uri"
require "nokogiri"
require "vebra/mappings"
require "vebra/parse"
require "vebra/api"
require "vebra/response"
require "vebra/client"
require "vebra/branch"
require "vebra/property"
require "vebra/version"

module Vebra

  def self.debugging?
    @@debug ||= false
  end

  def self.debug=(true_or_false)
    @@debug = true_or_false
  end

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
