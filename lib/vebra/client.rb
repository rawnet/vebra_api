module Vebra
  class Client

    attr_reader :auth, :config

    # client = Vebra::Client.new({
    #   :data_feed_id => 'ABC',
    #   :username     => 'user',
    #   :password     => 'pass'
    # })
  
    def initialize(config)
      data_feed_id = config[:data_feed_id]
      username     = config.delete(:username)
      password     = config.delete(:password)

      # a Vebra::Client *must* be initialized with a data feed id, username, and password
      if data_feed_id.nil? || username.nil? || password.nil?
        raise "Vebra: configuration hash must include `data_feed_id`, `username`, and `password`"
      end

      @auth   = { :username => username, :password => password }
      @config = config
    end

    # Proxy to call the appropriate method (or url) via the Vebra::API module
    def call(url_or_method, interpolations={})
      if url_or_method.is_a?(Symbol)
        raw = API.send("#{url_or_method}_url")
        url = API.compile(raw, @config, interpolations)
      end

      API.get(url || url_or_method, @auth)
    end

    # Call the API method to retrieve a collection of branches for this client,
    # and build a Vebra::Branch object for each
    def get_branches
      xml = call(:branches).parsed_response
      xml.css('branches branch').map { |b| Branch.new(b, self) }
    end

  end
end