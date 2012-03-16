module Vebra
  class Property
    attr_reader :attributes, :branch

    # property = Vebra::Property.new(nokogiri_xml_object, vebra_branch_object)

    def initialize(nokogiri_xml, branch)
      @branch     = branch
      @attributes = Vebra.parse(nokogiri_xml)
      set_attributes!
    end

    # Retrieve the full set of attributes for this branch
    def get_property
      nokogiri_xml = branch.client.call(url).parsed_response.css('property')
      @attributes.merge!(Vebra.parse(nokogiri_xml))
      set_attributes!
    end

    private

    # All attributes also have method readers
    def set_attributes!
      @attributes.each do |key, value|
        self.class.send(:define_method, key) do
          @attributes[key]
        end unless respond_to?(key)
      end
    end

  end
end