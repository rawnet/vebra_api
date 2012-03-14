module Vebra
  module API

    BASE_URI = 'http://webservices.vebra.com/export/{data_feed_id}/v3'

    class << self

      def branches_url
        BASE_URI + '/branch'
      end

      def branch_url
        branches_url + '/{branch_id}'
      end

      def properties_url
        branch_url + '/property'
      end

      def property_url
        properties_url + '/{property_id}'
      end

      # Compiles a url string, interpolating the dynamic components
      def compile(url_string, config, interpolations={})
        interpolations = config.merge(interpolations)
        url_string.gsub(/\{(\w+)\}/) do
          interpolations[($1).to_sym]
        end
      end

      # Performs the request to the Vebra API server
      def get(url, auth, retries=0)
        puts "Vebra: requesting #{url}"

        # build request object
        uri     = URI.parse(url)
        http    = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri)

        # add authorization header
        if auth[:token]
          puts "Vebra: authorizing via token"
          request.basic_token(auth[:token])
        else
          puts "Vebra: authorizing via basic auth"
          request.basic_auth(auth[:username], auth[:password])
        end

        # make the request
        response = http.request(request)

        # monitor for 401, signalling that our token has expired
        if response.code.to_i == 401
          # also monitor for multiple retries, which indicates
          # there has been a problem and we should wait
          if retries >= 3
            puts "Vebra: failed to authenticate"
            return response
          end
          # retry with basic auth
          retries += 1
          auth.delete(:token)
          return get(url, auth, retries)
        else
          # store the token for subsequent requests
          if response['token']
            auth[:token] = response['token']
            puts "Vebra: storing API token #{auth[:token]}"
          end
        end

        # return parsed response object
        Response.new(response)
      end

    end

  end
end