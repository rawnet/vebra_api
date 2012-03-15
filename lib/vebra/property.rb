module Vebra
  class Property

    # may extract user_field_1 as a new key, with user_field_2 as the value
    # need to confirm :sold_date etc with values present
    # need to easily identify if letting or sale

    attr_reader :attributes, :branch

    # Parse a Nokogiri XML fragment to extract the property attributes

    def initialize(nokogiri_xml, branch)
      @branch     = branch
      @attributes = Vebra.parse(nokogiri_xml)
      set_attributes!
    end

    # Parse an XML response using Nokogiri to extract additional
    # attributes for this property

    def get_property
      nokogiri_xml = branch.client.call(url).parsed_response.css('property')
      @attributes.merge!(Vebra.parse(nokogiri_xml))
      set_attributes!
    end

    private

    def set_attributes!
      @attributes.each do |key, value|
        self.class.send(:define_method, key) do
          @attributes[key]
        end unless respond_to?(key)
      end
    end

  end
end