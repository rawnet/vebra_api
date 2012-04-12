module Vebra
  class Property
    attr_reader :attributes, :branch, :xml

    # property = Vebra::Property.new(nokogiri_xml_object, vebra_branch_object)

    def initialize(nokogiri_xml, branch)
      @xml        = nokogiri_xml.to_xml
      @branch     = branch
      @attributes = Vebra.parse(nokogiri_xml)
    end

    # Retrieve the full set of attributes for this branch
    def get_property
      nokogiri_xml_full = branch.client.call(attributes[:url]).parsed_response
      @xml              = nokogiri_xml_full.to_xml
      nokogiri_xml      = nokogiri_xml_full.css('property')
      @attributes.merge!(Vebra.parse(nokogiri_xml))
    end

  end
end