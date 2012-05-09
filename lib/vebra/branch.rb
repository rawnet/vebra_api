module Vebra
  class Branch

    attr_reader :attributes, :client, :xml

    # branch = Vebra::Branch.new(nokogiri_xml_object, vebra_client_object)

    def initialize(nokogiri_xml, client)
      @xml        = nokogiri_xml.to_xml
      @client     = client
      @attributes = Vebra.parse(nokogiri_xml)
    end

    # Retrieve the full set of attributes for this branch
    def get_branch
      nokogiri_xml_full = client.call(attributes[:url]).parsed_response
      @xml              = nokogiri_xml_full.to_xml
      nokogiri_xml      = nokogiri_xml_full.css('branch')
      @attributes.merge!(Vebra.parse(nokogiri_xml))
    end

    # Call the API method to retrieve a collection of properties for this branch,
    # and build a Vebra::Property object for each
    def get_properties
      xml = client.call("#{attributes[:url]}/property").parsed_response
      xml.css('properties property').map { |p| Vebra::Property.new(p, self) }
    end

    # As above, but uses the API method to get only properties updated since a given date/time
    def get_properties_updated_since(datetime)
      year    = datetime.year
      month   = "%02d" % datetime.month
      day     = "%02d" % datetime.day
      hour    = "%02d" % datetime.hour
      minute  = "%02d" % datetime.min
      second  = "%02d" % datetime.sec
      base = API.compile(API::BASE_URI, client.config, {})
      xml = client.call("#{base}/property/#{year}/#{month}/#{day}/#{hour}/#{minute}/#{second}").parsed_response
      xml.css('propertieschanged property').map { |p| Vebra::Property.new(p, self) }
    end

  end
end