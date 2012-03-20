require "net/http"
require "uri"
require "nokogiri"
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

  def self.debug!
    @@debug = true
  end

  def self.tmp_dir=(tmp_dir)
    @@tmp_dir = tmp_dir
  end

  def self.tmp_dir
    @@tmp_dir ||= nil
  end

  # store the token to a temp directory
  def self.set_token(client_auth)
    return false if !Vebra.tmp_dir || !client_auth[:token]
    filename = "vebra-#{client_auth[:username]}-token"
    File.open(File.join(Vebra.tmp_dir, filename), 'w') do |f|
      f.write(client_auth[:token])
    end
  end

  # retrieve the token from the temp directory
  def self.get_token(client_auth)
    return false unless Vebra.tmp_dir
    filename = "vebra-#{client_auth[:username]}-token"
    path = File.join(Vebra.tmp_dir, filename)
    File.exists?(path) ? File.open(path, 'r').read : false
  end

  def self.delete_token(client_auth)
    return false unless Vebra.tmp_dir
    filename = "vebra-#{client_auth[:username]}-token"
    path = File.join(Vebra.tmp_dir, filename)
    File.exists?(path) ? File.delete(path) : false
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
