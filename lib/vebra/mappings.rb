module Vebra
  class << self

    def mappings
      {
        'firmid'      => 'firm_id',
        'branchid'    => 'branch_id',
        'lastchanged' => 'last_changed',
        'solddate'    => 'sold_date',
        'leaseend'    => 'lease_end',
        'soldprice'   => 'sold_price',
        'ground_rent' => 'ground_rent',
        'userfield1'  => 'user_field_1', 
        'userfield2'  => 'user_field_2' 
      }
    end

    def map_hash(hash)
      hash.inject({}) do |result, (key, value)|
        key    = key.to_s.downcase
        mapped = mappings[key]
        value  = map_hash(value) if value.is_a?(Hash)
        result[(mapped || key).to_sym] = value.respond_to?(:empty?) && value.empty? ? nil : value
        result
      end
    end

    def xml_to_hash(xml)
      hash = Hash.from_xml(xml.to_s)
      map_hash(hash)
    end

  end
end