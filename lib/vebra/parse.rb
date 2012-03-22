module Vebra
  class << self

    # After converting an XML document to a Nokogiri XML object,
    # this method generates an opinionated, well-formed Ruby hash
    # tailored specifically for Vebra output

    def parse(nokogiri_xml)
      customise(parse_node(nokogiri_xml))
    end

    private

    # Nokogiri XML object => Ruby hash

    def parse_node(node)
      # bypass the top-level (document) node
      if node.respond_to?(:root)
        node = node.root
      end

      # searching within a document returns a node set, in which
      # case we need to retrieve the first element
      if !node.respond_to?(:element?)
        node = node[0]
      end

      if node.element?
        # if an element, check for presence of (valid) attributes and/or children;
        # otherwise, set value to nil
        node_hash = {}

        # if the node has attributes, extract them
        unless node.attributes.empty?
          attributes = node.attributes
          node_hash[:attributes] = attributes.inject({}) do |result, (key, value)|
            attribute = attributes[key]
            if attribute.namespace.nil? # ignore namespace schemas
              attr_key = (mappings[key] || key).to_sym
              result[attr_key] = parse_value(attribute.value)
            end
            result
          end

          # if the attributes hash is still empty, remove it
          node_hash.delete(:attributes) if node_hash[:attributes].empty?
        end

        # merge the attributes hash with the main object hash in some circumstances
        if merge_attributes.include?(node.name.to_sym) && !node_hash[:attributes].nil? && node_hash[:attributes] != {}
          node_hash = node_hash.delete(:attributes)
        end

        # iterate over the node's children, if there are any
        node.children.each do |child_node|
          child_result = parse_node(child_node)

          # convert { :value => #<value> } to #<value>
          if child_result.respond_to?(:keys) && child_result.size == 1 && child_result.keys.first == :value
            child_result = child_result.values.first
          end

          # map codes to their string equivalent
          if lookup = lookups[child_node.name]
            child_result = send("#{lookup}_lookup", child_result)
          end

          # define or extend the attribute
          unless child_node.name == "text" && child_result.nil?
            attr_key = (mappings[child_node.name] || child_node.name).downcase.to_sym
            attr_key = :value if attr_key == :text
            if !node_hash[attr_key]
              # if this attribute hasn't yet been set, set it's value
              if child_result && collections.include?(attr_key)
                # if this key is known to hold a collection, force it
                first_value = child_result.values.first
                node_hash[attr_key] = first_value.respond_to?(:<<) ? first_value : [ first_value ]
              else
                # set the value
                node_hash[attr_key] = child_result
              end
            elsif child_result
              # if this attribute already exists, create or extend a collection
              if node_hash[attr_key].respond_to?(:<<) && node_hash[attr_key].respond_to?(:each)
                # if the attribute's value is a collection already, add inject the new value
                node_hash[attr_key] << child_result
              else
                # otherwise, build a new collection
                node_hash[attr_key] = [ node_hash[attr_key], child_result ]
              end
            end
          end
        end

        return node_hash.empty? ? nil : node_hash
      else
        # this is a text node; parse the value
        parse_value(node.content.to_s)
      end
    end

    # As all values are initially strings, we try to convert them to
    # Ruby objects where possible

    def parse_value(value)
      if value.is_a?(String)
        if value.to_i.to_s == value
          value.to_i
        elsif value.to_f.to_s == value
          value.to_f
        elsif value.gsub(/^\s+|\s+$/, '') == '' || value == '(Not Specified)'
          nil
        elsif /^\d{2}\/\d{2}\/\d{4}$/ =~ value
          Date.parse(value)
        elsif /^\d{2}\/\d{2}\/\d{4}\s\d{2}:\d{2}:\d{2}$/ =~ value
          Time.parse(value)
        else
          value
        end
      else
        value
      end
    end

    # Vebra don't have consistent key names, so we map them where appropriate

    def mappings
      {
        'propertyid'  => 'property_id',
        'prop_id'     => 'vebra_ref',
        'firmid'      => 'firm_id',
        'branchid'    => 'branch_id',
        'lastchanged' => 'last_changed',
        'solddate'    => 'sold_on',
        'leaseend'    => 'lease_ends_on',
        'soldprice'   => 'sold_price',
        'groundrent'  => 'ground_rent',
        'userfield1'  => 'user_field_1', 
        'userfield2'  => 'user_field_2' ,
        'updated'     => 'updated_at',
        'FirmID'      => 'firm_id',
        'BranchID'    => 'branch_id',
        'web_status'  => 'status',
        'available'   => 'available_on',
        'uploaded'    => 'uploaded_on',
        'price'       => 'price_attributes'
      }
    end

    # These attributes should always form an array, even with only a single item
    def collections
      %w( paragraphs bullets files ).map(&:to_sym)
    end

    # These attributes do not require a separate "attributes" attribute
    def merge_attributes
      %w( price area paragraph bullet file ).map(&:to_sym)
    end

    # The values of these attributes are codes which are mapped via
    # their corresponding lookup (see below)
    def lookups
      {
        'web_status' => 'property_status',
        'furnished'  => 'furnished_status'
      }
    end

    # Map the web_status code
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

    # Map the furnished code
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

    # Map the let_type code
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

    # After parsing & converting the Nokogiri object into a Ruby hash,
    # some additional changes are required to better structure the data

    def customise(hash)
      # was: { :attributes => { :id => #<value> } }
      # now: { :attributes => { :vebra_id => #<value> } }
      if hash[:attributes] && hash[:attributes][:id]
        hash[:vebra_ref] = hash[:attributes].delete(:id)
      end

      # was: { :price_attributes => { :value => #<value>, ... } }
      # now: { :price_attributes => { ... }, :price => #<value> }
      if hash[:price_attributes]
        hash[:price] = hash[:price_attributes].delete(:value)
      end

      # was: { :type => [#<value>, #<value>] } or: { :type => #<value> }
      # now: { :property_type => #<value> }
      if hash[:type]
        hash[:property_type] = hash.delete(:type)
        hash[:property_type] = hash[:property_type].first if hash[:property_type].respond_to?(:each)
      end

      # was: { :reference => { :agents => #<value> } }
      # now: { :agent_reference => #<value> }
      if hash[:reference] && hash[:reference].size == 1 && hash[:reference].keys.first == :agents
        reference = hash.delete(:reference)
        hash[:agent_reference] = reference.delete(:agents)
      end

      # was: { :area => [ #<area - imperial>, #<area - metric> ] }
      # now: { :area => { :imperial => #<imperial>, :metric => #<metric> } }
      if area = hash[:area]
        hash[:area] = {}
        area.each do |a|
          hash[:area][a.delete(:measure).to_sym] = a
        end
      end

      # was: { :bullets => [ { :value => #<value> }, { :value => #<value> } ] }
      # now: { :bullets => [ #<value>, #<value> ] }
      if hash[:bullets]
        hash[:bullets].map! do |b|
          b[:value]
        end
      end

      # was: { :paragraphs => [ #<paragraph - type a, #<paragraph - type b> ] }
      # now: { :type_a => [ #<paragraph> ], :type_b => [ #<paragraph> ] }
      if paragraphs = hash.delete(:paragraphs)
        # extract each paragraph type into separate collections
        hash[:rooms]          = paragraphs.select { |p| p.delete(:id); p[:type] == 0; }
        hash[:energy_reports] = paragraphs.select { |p| p.delete(:id); p[:type] == 1; }
        hash[:disclaimers]    = paragraphs.select { |p| p.delete(:id); p[:type] == 2; }

        %w( rooms energy_reports disclaimers ).map(&:to_sym).each do |paragraph_type|
          hash[paragraph_type].each { |f| f.delete(:type) }
        end
      end

      # was: { :files => [ #<file - type a>, #<file - type b> ] }
      # now: { :files => { :type_a => [ #<file> ], :type_b => [ #<file> ] } }
      if files = hash.delete(:files)
        # extract each file type into separate collections
        hash[:files] = {
          :images              => files.select { |f| f.delete(:id); f[:type] == 0 },
          :maps                => files.select { |f| f.delete(:id); f[:type] == 1 },
          :floorplans          => files.select { |f| f.delete(:id); f[:type] == 2 },
          :tours               => files.select { |f| f.delete(:id); f[:type] == 3 },
          :ehouses             => files.select { |f| f.delete(:id); f[:type] == 4 },
          :ipixes              => files.select { |f| f.delete(:id); f[:type] == 5 },
          :pdfs                => files.select { |f| f.delete(:id); f[:type] == 7 },
          :urls                => files.select { |f| f.delete(:id); f[:type] == 8 },
          :energy_certificates => files.select { |f| f.delete(:id); f[:type] == 9 },
          :info_packs          => files.select { |f| f.delete(:id); f[:type] == 10 }
        }

        %w( images maps floorplans tours ehouses ipixes pdfs urls energy_certificates info_packs ).map(&:to_sym).each do |file_type|
          hash[:files][file_type].each { |f| f.delete(:type) }
        end
      end

      # was: { :hip => { :energy_performance => #<energy performance> } }
      # now: { :energy_performance => #<energy performance> }
      if hip = hash.delete(:hip)
        hash[:energy_performance] = hip[:energy_performance]
      end

      # was: { :street => #<street>, :town => #<town>, ... }
      # now: { :address => { :street => #<street>, :town => #<town>, ... } }
      if !hash[:address] && hash[:street] && hash[:town] && hash[:county] && hash[:postcode]
        hash[:address] = {
        :street   => hash.delete(:street),
        :town     => hash.delete(:town),
        :county   => hash.delete(:county),
        :postcode => hash.delete(:postcode)
        }
      end

      # was: { :attributes => { :database => 1 }, :web_status => ['For Sale', 'To Let'] }
      # now: { :attributes => { :database => 1 }, :web_status => 'For Sale', :grouping => :sales }
      if hash[:attributes] && hash[:attributes][:database]
        hash[:group] = case hash[:attributes][:database]
          when 1 then :sales
          when 2 then :lettings
        end

        if hash[:status]
          hash[:status] = hash[:status][hash[:attributes][:database]-1]
        end
      end

      # was: { :garden => nil }
      # now: { :garden => false }
      hash[:garden] = !!hash[:garden] if hash.keys.include?(:garden)

      # was: { :parking => nil }
      # now: { :parking => false }
      hash[:parking] = !!hash[:parking] if hash.keys.include?(:parking)

      hash
    end

  end
end