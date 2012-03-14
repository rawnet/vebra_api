require File.join(File.dirname(__FILE__), '../spec_helper')

describe Vebra::API do

  before do
    FakeWeb.clean_registry
  end

  it "should attempt to authenticate on the initial request using password-based http authentication" do
    FakeWeb.register_uri(:get, 'http://webservices.vebra.com/export/ABC/v3/branch', :body => "Unauthorized", :status => ["401", "Unauthorized"])
    FakeWeb.register_uri(:get, 'http://user:pass@webservices.vebra.com/export/ABC/v3/branch', :body => "Authorized", :token => 'ABC123')

    client = Vebra::Client.new({
      :data_feed_id => 'ABC',
      :username     => 'user',
      :password     => 'pass'
    })

    res = Vebra::API.get('http://webservices.vebra.com/export/ABC/v3/branch', client.auth).response_object
    res.code.to_i.should eq(200)
  end

  it "should store the token from the response header after successful initial authentication" do
    FakeWeb.register_uri(:get, 'http://webservices.vebra.com/export/ABC/v3/branch', :body => "Unauthorized", :status => ["401", "Unauthorized"])
    FakeWeb.register_uri(:get, 'http://user:pass@webservices.vebra.com/export/ABC/v3/branch', :body => "Authorized", :token => 'ABC123')

    client = Vebra::Client.new({
      :data_feed_id => 'ABC',
      :username     => 'user',
      :password     => 'pass'
    })

    Vebra::API.get('http://webservices.vebra.com/export/ABC/v3/branch', client.auth).response_object
    
    client.auth[:token].should eq('ABC123')
  end

  it "should attempt to authenticate on subsequent requests using token-based http authentication" do
    FakeWeb.register_uri(:get, 'http://webservices.vebra.com/export/ABC/v3/branch', :body => "Unauthorized", :status => ["401", "Unauthorized"])
    FakeWeb.register_uri(:get, 'http://user:pass@webservices.vebra.com/export/ABC/v3/branch', :body => "Authorized", :token => 'ABC123')

    client = Vebra::Client.new({
      :data_feed_id => 'ABC',
      :username     => 'user',
      :password     => 'pass'
    })

    res = Vebra::API.get('http://webservices.vebra.com/export/ABC/v3/branch', client.auth).response_object

    FakeWeb.clean_registry
    FakeWeb.register_uri(:get, 'http://ABC123@webservices.vebra.com/export/ABC/v3/branch', :body => "Authorized")
    FakeWeb.register_uri(:get, 'http://user:pass@webservices.vebra.com/export/ABC/v3/branch', :body => "Forbidden", :status => ["403", "Forbidden"])

    res = Vebra::API.get('http://webservices.vebra.com/export/ABC/v3/branch', client.auth).response_object
    res.code.to_i.should eq(200)
  end

  it "should discard the stored token and re-authenticate with password-based http authentication if a 401 response is returned" do
    FakeWeb.register_uri(:get, 'http://webservices.vebra.com/export/ABC/v3/branch', :body => "Unauthorized", :status => ["401", "Unauthorized"])
    FakeWeb.register_uri(:get, 'http://user:pass@webservices.vebra.com/export/ABC/v3/branch', :body => "Authorized", :token => 'ABC123')

    client = Vebra::Client.new({
      :data_feed_id => 'ABC',
      :username     => 'user',
      :password     => 'pass'
    })

    res = Vebra::API.get('http://webservices.vebra.com/export/ABC/v3/branch', client.auth).response_object

    FakeWeb.clean_registry
    FakeWeb.register_uri(:get, 'http://ABC123@webservices.vebra.com/export/ABC/v3/branch', :body => "Unauthorized", :status => ["401", "Unauthorized"])
    FakeWeb.register_uri(:get, 'http://user:pass@webservices.vebra.com/export/ABC/v3/branch', :body => "Authorized", :token => 'XYZ789')

    res = Vebra::API.get('http://webservices.vebra.com/export/ABC/v3/branch', client.auth).response_object
    
    client.auth[:token].should eq('XYZ789')
    res.code.to_i.should eq(200)
  end

end