require File.join(File.dirname(__FILE__), '../spec_helper')

describe Vebra::Client do

  before do
    FakeWeb.clean_registry
  end
  
  it "should create a new Client object when provided authentication credentials" do
    client = Vebra::Client.new({
      :data_feed_id => 'ABC',
      :username     => 'user',
      :password     => 'pass'
    })

    client.auth[:username].should eq('user')
    client.auth[:password].should eq('pass')
    client.config[:data_feed_id].should eq('ABC')
  end
  
  it "should not create a new Client object when not provided full authentication credentials" do
    lambda { Vebra::Client.new }.should raise_error
    lambda { Vebra::Client.new({}) }.should raise_error
    lambda { Vebra::Client.new({
      :data_feed_id => 'ABC',
      :username     => 'user'
    }) }.should raise_error
    lambda { Vebra::Client.new({
      :data_feed_id => 'ABC',
      :password     => 'pass'
    }) }.should raise_error
    lambda { Vebra::Client.new({
      :username     => 'user',
      :password     => 'user'
    }) }.should raise_error
  end

end