require 'vebra'
Bundler.require(:development)
FakeWeb.allow_net_connect = false

# RSpec.configure do |config|
#   config.after(:each) do
#     FakeWeb.clean_registry
#   end
# end


# response_body = File.open(File.join(File.dirname(__FILE__), 'sample.xml'), "rb").read
# FakeWeb.register_uri(:get, /webservices\.vebra\.com/, :body => response_body)


# FakeWeb.register_uri(:get, /webservices\.vebra\.com/, :body => "Unauthorized", :status => ["401", "Unauthorized"])
# FakeWeb.register_uri(:get, /user\:pass@webservices\.vebra\.com/, :body => "Authorized", :token => 'ABC123')