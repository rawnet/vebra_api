module Vebra
  class << self

    # After converting an XML document to a Nokogiri XML object,
    # this method generates an opinionated, well-formed Ruby hash
    # tailored specifically for Vebra output

    def parse(nokogiri_xml)
      customise(parse_node(nokogiri_xml))
    end

    private

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
              if collections.include?(attr_key)
                # if this key is known to hold a collection, force it
                first_value = child_result.values.first
                node_hash[attr_key] = first_value.respond_to?(:<<) ? first_value : [ first_value ]
              else
                # set the value
                node_hash[attr_key] = child_result
              end
            elsif child_result
              # if this attribute already exists, create or extend a collection
              if node_hash[attr_key].respond_to?(:<<)
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

    def mappings
      {
        'propertyid'  => 'property_id',
        'firmid'      => 'firm_id',
        'branchid'    => 'branch_id',
        'lastchanged' => 'last_changed',
        'solddate'    => 'sold_date',
        'leaseend'    => 'lease_end',
        'soldprice'   => 'sold_price',
        'groundrent'  => 'ground_rent',
        'userfield1'  => 'user_field_1', 
        'userfield2'  => 'user_field_2' ,
        'updated'     => 'updated_at',
        'FirmID'      => 'firm_id',
        'BranchID'    => 'branch_id'
      }
    end

    def collections
      %w( paragraphs bullets files ).map(&:to_sym)
    end

    def merge_attributes
      %w( price area paragraph bullet file ).map(&:to_sym)
    end

    def lookups
      {
        'web_status' => 'property_status',
        'furnished'  => 'furnished_status'
      }
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

    def customise(hash)
      if hash[:reference] && hash[:reference].size == 1 && hash[:reference].keys.first == :agents
        reference = hash.delete(:reference)
        hash[:agent_reference] = reference.delete(:agents)
      end

      if area = hash[:area]
        hash[:area] = {}
        area.each do |a|
          hash[:area][a.delete(:measure).to_sym] = a
        end
      end

      if hash[:bullets]
        hash[:bullets].map! do |b|
          b[:value]
        end
      end

      if paragraphs = hash.delete(:paragraphs)
        # extract each paragraph type into separate collections
        hash[:rooms]          = paragraphs.select { |p| p.delete(:id); p[:type] == 0; }
        hash[:energy_reports] = paragraphs.select { |p| p.delete(:id); p[:type] == 1; }
        hash[:disclaimers]    = paragraphs.select { |p| p.delete(:id); p[:type] == 2; }

        %w( rooms energy_reports disclaimers ).map(&:to_sym).each do |paragraph_type|
          hash[paragraph_type].each { |f| f.delete(:type) }
        end
      end

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

      if hip = hash.delete(:hip)
        hash[:energy_performance] = hip[:energy_performance]
      end

      hash
    end

  end
end