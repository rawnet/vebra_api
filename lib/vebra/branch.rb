module Vebra
  class Branch

    attr_reader :attributes, :client

    # branch = Vebra::Branch.new(nokogiri_xml_object, vebra_client_object)

    def initialize(nokogiri_xml, client)
      @client     = client
      @attributes = Vebra.parse(nokogiri_xml)
      set_attributes!
    end

    # Retrieve the full set of attributes for this branch
    def get_branch
      nokogiri_xml = client.call(url).parsed_response.css('branch')
      @attributes.merge!(Vebra.parse(nokogiri_xml))
      set_attributes!
    end

    # Call the API method to retrieve a collection of properties for this branch,
    # and build a Vebra::Property object for each
    def get_properties
      xml = client.call("#{url}/property").parsed_response
      xml.css('properties property').map { |p| Property.new(p, self) }
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