module Vebra
  class Property

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
      res = branch.client.call(url)
      nokogiri_xml = res.parsed_response.css('property')
      @attributes.merge!(Vebra.parse(nokogiri_xml))
      set_attributes!
      parse_attributes!
    end

    def latitude
      @attributes[:latitude].to_f
    end

    def longitude
      @attributes[:longitude].to_f
    end

    private

    def set_attributes!
      @attributes[:attributes].delete(:noNamespaceSchemaLocation) if @attributes[:attributes]
      @attributes.each do |key, value|
        self.class.send(:define_method, key) do
          @attributes[key]
        end unless respond_to?(key)
      end
    end

    # may extract user_field_1 as a new key, with user_field_2 as the value
    # not sure what to do about :area
    # need to confirm :sold_date etc with values present
    # need to figure out what to do with "paragraphs" & "files" (of differing types)
    # for the collection items, beware if the collection only contains 1!
    # should really write some tests around this: mock the un-modified XML and plot the expected results (also test collections with 1 item!)
    # need to easily identify if letting or sale
    def parse_attributes!
      @attributes[:last_changed]  = Time.parse(@attributes[:last_changed])
      @attributes[:reference]     = @attributes[:reference][:agents]
      @attributes[:available]     = Date.parse(@attributes[:available])
      @attributes[:uploaded]      = Date.parse(@attributes[:uploaded])
      @attributes[:web_status]    = property_status_lookup(@attributes[:web_status])
      @attributes[:type]          = @attributes[:type].detect { |t| !t.nil? && t != '' && t != '(Not Specified)' }
      @attributes[:furnished]     = furnished_status_lookup(@attributes[:furnished])
      @attributes[:bullets]       = @attributes[:bullets][:bullet]
      @attributes[:files]         = @attributes[:files][:file]
      @attributes[:paragraphs]    = @attributes[:paragraphs][:paragraph]
      [ :sold_date, :lease_end, :instructed, :sold_price, :garden, :parking ].each do |nullable|
        if @attributes[nullable][:attributes] && @attributes[nullable][:attributes][:nil]
          @attributes[nullable] = nil
        elsif [ :sold_date, :lease_end ].include?(nullable)
          # @attributes[nullable] = Date.parse(@attributes[nullable]) # need example first
        end
      end
    end

    def property_status_lookup(code)
      case code.to_i
        when 0   then [ 'For Sale', 'To Let' ]
        when 1   then [ 'Under Offer', 'Let' ]
        when 2   then [ 'Sold', 'Under Offer' ]
        when 3   then [ 'SSTC', 'Reserved' ]
        when 4   then [ 'For Sale By Auction', 'Let Agreed' ]
        when 5   then [ 'Reserved' ]
        when 6   then [ 'New Instruction' ]
        when 7   then [ 'Just on Market' ]
        when 8   then [ 'Price Reduction' ]
        when 9   then [ 'Keen to Sell' ]
        when 10  then [ 'No Chain' ]
        when 11  then [ 'Vendor will pay stamp duty' ]
        when 12  then [ 'Offers in the region of' ]
        when 13  then [ 'Guide Price' ]
        when 200 then [ 'For Sale', 'To Let' ]
        when 201 then [ 'Under Offer', 'Let' ]
        when 202 then [ 'Sold', 'Under Offer' ]
        when 203 then [ 'SSTC', 'Reserved' ]
        when 214 then [ 'Under Offer', 'Let' ]
        when 255 then []
        else nil
      end
    end

    def furnished_status_lookup(code)
      case code.to_i
        when 0 then 'Furnished'
        when 1 then 'Part Furnished'
        when 2 then 'Un-Furnished'
        when 3 then 'Not Specified'
        when 4 then 'Furnished / Un-Furnished'
        else nil
      end
    end

    def let_type_lookup(code)
      case code.to_i
        when 0 then 'Not Specified'
        when 1 then 'Long Term'
        when 2 then 'Short Term'
        when 3 then 'Student'
        when 4 then 'Commercial'
        else nil
      end
    end

  end
end