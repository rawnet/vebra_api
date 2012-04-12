require "net/http"
require "uri"
require "nokogiri"
require "vebra/config"
require "vebra/parse"
require "vebra/api"
require "vebra/response"
require "vebra/client"
require "vebra/branch"
require "vebra/property"
require "vebra/helpers"
require "vebra/version"

module Vebra
  class << self

    def config(&config_block)
      config_block[Vebra::Config]
    end

    def read_cache
      return {} if !Vebra.tmp_dir
      path = File.join(Vebra.tmp_dir, "vebra-cache.yml")
      File.exists?(path) ? YAML.load_file(path) : {}
    end

    def write_cache(new_cache)
      return false if !Vebra.tmp_dir
      path = File.join(Vebra.tmp_dir, "vebra-cache.yml")
      File.open(path, 'w') do |f|
        f.write(new_cache.to_yaml)
      end
    end

    # store the token to a temp directory
    def set_token(client_auth)
      return false if !client_auth[:token]
      new_cache = read_cache
      new_cache['token'] = client_auth[:token]
      write_cache(new_cache)
    end

    # retrieve the token from the temp directory
    def get_token
      read_cache['token']
    end

    # remove a stale token
    def delete_token
      new_cache = read_cache
      new_cache.delete('token')
      write_cache(new_cache)
    end

    # set the date & time when the properties were last updated
    def set_last_updated_at(datetime)
      new_cache = read_cache
      new_cache['last_updated_at'] = datetime
      write_cache(new_cache)
    end

    # get the date & time when the properties were last updated
    def get_last_updated_at
      read_cache['last_updated_at']
    end

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
