module Vebra
  module Helpers
    class << self

      def live_update(property)
        return false unless property_class = Vebra.models[:property]
        property_class = property_class[:model_class]

        # find & update or build a new property
        property_model = property_class.find_or_initialize_by_vebra_ref(property.vebra_ref)

        # extract accessible attributes for the property
        property_accessibles = property_class.accessible_attributes.map(&:to_sym)
        property_attributes = property.attributes.inject({}) do |result, (key, value)|
          result[key] = value if property_accessibles.include?(key)
        end

        # update the property model's attributes
        property_model.attributes = property_model.attributes.merge(property_attributes)

        # find & update or build a new address
        if address_class = Vebra.models[:address]
          address_class = address_class[:model_class]
          address_model = property_model.send(Vebra.models[:property][:address_method] || :address) || property_model.send("build_#{Vebra.models[:property][:address_method] || :address}")

          # extract accessible attributes for the address
          address_accessibles = address_class.accessible_attributes.map(&:to_sym)
          address_attributes = property.attributes[:address].inject({}) do |result, (key, value)|
            result[key] = value if address_accessibles.include?(key)
          end

          # update the address model's attributes
          address_model.attributes = address_model.attributes.merge(address_attributes)
        end

        # find & update or build new rooms
        if room_class = Vebra.models[:room]
          room_class = room_class[:model_class]

          # accessible attributes for the rooms
          room_accessibles = room_class.accessible_attributes.map(&:to_sym)

          # delete any rooms which are no longer present
          refs_to_delete = property_model.send(Vebra.models[:room][:rooms_method] || :rooms).map(&:vebra_ref) - property.attributes[:rooms].map(&:vebra_ref)
          property_model.send(Vebra.models[:room][:rooms_method] || :rooms).each do |room|
            room.destroy if refs_to_delete.include?(room.vebra_ref)
          end

          # find & update or build new rooms
          property.attributes[:rooms].each do |room|
            room_model = room_class.find_or_initialize_by_property_id_and_vebra_ref(property_model.id, room.vebra_ref)

            # extract accessible attributes for the room
            room_attributes = room.attributes.inject({}) do |result, (key, value)|
              result[key] = value if room_accessibles.include?(key)
            end

            # update the room model's attributes
            room_model.attributes = room_model.attributes.merge(room_attributes)
          end
        end

        # find & update or build new file attachments
        if file_class = Vebra.models[:file]
          file_class = file_class[:model_class]

          # accessible attributes for the files
          file_accessibles = file_class.accessible_attributes.map(&:to_sym)

          # first normalize the collection (currently nested collections)
          property_files = property.attributes[:files].inject([]) do |result, (kind, collection)|
            collection.each do |file|
              file[:type] = kind.to_s.singularize.camelize
              file["remote_#{Vebra.models[:file][:attachment_method]}_url".to_sym] = file.delete(:url)
              result << file
            end

            result
          end

          # delete any rooms which are no longer present
          refs_to_delete = property_model.send(Vebra.models[:file][:files_method] || :files).map(&:vebra_ref) - property.attributes[:rooms].map(&:vebra_ref)
          property_model.send(Vebra.models[:file][:files_method] || :files).each do |file|
            file.destroy if refs_to_delete.include?(file.vebra_ref)
          end

          # find & update or build new files
          property_files.each do |file|
            file_model = file_class.find_or_initialize_by_property_id_and_vebra_ref(property_model.id, file.vebra_ref)

            # extract accessible attributes for the file
            file_attributes = file.attributes.inject({}) do |result, (key, value)|
              result[key] = value if file_accessibles.include?(key)
            end

            # update the room model's attributes
            file_model.attributes = file_model.attributes.merge(file_attributes)
          end
        end
      end

    end
  end
end