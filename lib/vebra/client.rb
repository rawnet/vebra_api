module Vebra
  class Client

    attr_reader :auth, :config

    # NHLJQGBIQPBOOHSGQBSHPWYHBPISFIXLRWTONOYQIHPIPQEAPD

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

      @auth     = { :username => username, :password => password }
      @config   = config
    end

    # Proxy to call the appropriate methods in the API module
    def call(url_or_method, interpolations={})
      if url_or_method.is_a?(Symbol)
        raw = API.send("#{url_or_method}_url")
        url = API.compile(raw, @config, interpolations)
      end

      API.get(url || url_or_method, @auth)
    end

    # Retrieve a list of branches
    def get_branches
      xml = call(:branches).parsed_response
      # build a collection of Branch objects
      xml.css('branches branch').map { |b| Branch.new(b, self) }
    end

  end
end