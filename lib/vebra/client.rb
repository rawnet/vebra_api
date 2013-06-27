module Vebra
  class Client

    attr_reader :auth, :config, :branch

    # client = Vebra::Client.new(:data_feed_id => 'ABC', :username => 'user', :password => 'pass')
  
    def initialize(*args)
      config = args[0]
      data_feed_id = config[:data_feed_id]
      username     = config.delete(:username)
      password     = config.delete(:password)

      # a Vebra::Client *must* be initialized with a data feed id, username, and password
      if data_feed_id.nil? || username.nil? || password.nil?
        raise "[Vebra]: configuration hash must include `data_feed_id`, `username`, and `password`"
      end

      @auth   = { :username => username, :password => password }
      @config = config

      # if there is a saved token for this client, grab it
      if token = Vebra.get_token
        @auth[:token] = token
      end
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

    # Helper method to get and cache the first branch
    def get_branch(branch_id=nil)
      if branch_id == nil && url = Vebra.read_cache['branch_url']
        build_branch_with_url(url)
      else
        fetch_and_cache_branch(branch_id)
      end
    end

    private

    def fetch_and_cache_branch(branch_id=nil)
      branches = get_branches
      if branch_id
        branch = branches.find { |b| b.attributes[:branch_id] == branch_id}
      else
        branch = branches.first
      end

      new_cache = Vebra.read_cache
      new_cache['branch_url'] = branch.attributes[:url]
      Vebra.write_cache(new_cache)
      return branch
    end

    def build_branch_with_url(url)
      branch = Vebra::Branch.allocate
      branch.instance_variable_set("@client", Vebra.client)
      branch.instance_variable_set("@attributes", { :url => url })
      return branch
    end
  end
end