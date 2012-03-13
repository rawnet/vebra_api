module Vebra
  class Client

    # Initialize a new client:
    # 
    # client = Vebra::Client.new({
    #   :data_feed_id => 'ABC',
    #   :username     => 'user',
    #   :password     => 'pass'
    # })
  
    def initialize(config)
      data_feed_id = config[:data_feed_id]
      username     = config.delete(:username)
      password     = config.delete(:password)

      if data_feed_id.nil? || username.nil? || password.nil?
        raise "Vebra: configuration hash must include `data_feed_id`, `username`, and `password`"
      end

      @auth   = { :username => username, :password => password }
      @config = config
    end

    attr_reader :auth, :config

    # Proxy to call the appropriate methods in the API module
    def call(api_method, interpolations={})
      url = API.compile_url(API.send("#{api_method}_url"), @config, interpolations)
      API.get(url, @auth)
    end

    # Retrieve a list of branches
    def get_branches
      doc = call(:branches).parsed_response
      # build a collection of Branch objects
      doc.css('branches branch').map { |b| Branch.new(b, self) }
    end

  end
end