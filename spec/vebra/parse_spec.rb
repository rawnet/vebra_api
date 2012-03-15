require 'time'
require File.join(File.dirname(__FILE__), '../spec_helper')
require File.join(File.dirname(__FILE__), '../support/expected_output')

class Hash
  def diff(h2)
    dup.delete_if { |k, v| h2[k] == v }.merge!(h2.dup.delete_if { |k, v| has_key?(k) })
  end
end

describe Vebra do

  before do
    FakeWeb.clean_registry
  end

  it "should convert Nokogiri XML to a Ruby hash tailored for Vebra" do
    nokogiri_xml  = Nokogiri::XML(File.open(File.join(File.dirname(__FILE__), '../support/sample_input.xml'), "rb").read)
    expected_hash = PropertyHash
    parsed_output = Vebra.parse(nokogiri_xml)

    parsed_output.diff(expected_hash).should be_empty
  end

end