module Vebra
  module Helpers
    class << self

      # fetch all properties (Vebra objects)
      def fetch_properties(all_time=false)
        return false unless Vebra.client
        branch = Vebra.client.get_branch
        last_update = Vebra.get_last_updated_at
        properties = if !all_time && last_update
          branch.get_properties_updated_since(last_update)
        else
          branch.get_properties
        end
        properties.each { |p| p.get_property unless p.attributes[:action] == 'deleted' }
        return properties
      end

      # fetch and perform a live update on all properties
      def update_properties!
        properties = fetch_properties
        length = properties.length
        counter = 0
        properties.each do |property|
          counter += 1
          if Vebra.debugging?
            puts "[Vebra]: #{counter}/#{length}: live updating property with Vebra ref: #{property.attributes[:vebra_ref]}"
          end
          live_update!(property)
          Vebra.set_last_updated_at(Time.now) if counter == length
        end
      end

      # build, update, or remove the property in the database
      def live_update!(property)
        property_class = Vebra.models[:property][:class].to_s.camelize.constantize

        # ensure we have the full property attributes
        property.get_property if !property.attributes[:status] && property.attributes[:action] != 'deleted'

        # find & update or build a new property
        property_model = property_class.find_or_initialize_by_vebra_ref(property.attributes[:vebra_ref])

        # if the property has been deleted, mark it appropriately and move on
        if property.attributes[:action] == 'deleted'
          return property_model.destroy
        end

        # extract accessible attributes for the property
        property_accessibles = property_class.accessible_attributes.map(&:to_sym)
        property_attributes = property.attributes.inject({}) do |result, (key, value)|
          result[key] = value if property_accessibles.include?(key)
          result
        end

        # update the property model's attributes
        property_model.no_callbacks = true if property_model.respond_to?(:no_callbacks)
        property_model.update_attributes(property_attributes)

        # find & update or build a new address
        if Vebra.models[:address]
          address_class = Vebra.models[:address][:class].to_s.camelize.constantize
          address_model = property_model.send(Vebra.models[:property][:address_method])
          address_model = property_model.send("build_#{Vebra.models[:property][:address_method]}") unless address_model

          # extract accessible attributes for the address
          address_accessibles = address_class.accessible_attributes.map(&:to_sym)
          address_attributes = property.attributes[:address].inject({}) do |result, (key, value)|
            result[key] = value if address_accessibles.include?(key)
            result
          end

          # update the address model's attributes
          address_model.update_attributes(address_attributes)
        end

        # find & update or build new rooms
        if Vebra.models[:room]
          room_class = Vebra.models[:room][:class].to_s.camelize.constantize

          # accessible attributes for the rooms
          room_accessibles = room_class.accessible_attributes.map(&:to_sym)

          # delete any rooms which are no longer present
          property_rooms = property.attributes[:rooms] || []
          property_model_rooms = property_model.send(Vebra.models[:property][:rooms_method])
          refs_to_delete = property_model_rooms.map(&:vebra_ref) - property_rooms.map { |r| r[:vebra_ref] }
          property_model_rooms.each do |room|
            room.destroy if refs_to_delete.include?(room.vebra_ref)
          end

          # find & update or build new rooms
          property_rooms.each do |room|
            room_model = room_class.find_by_property_id_and_vebra_ref(property_model.id, room[:vebra_ref])
            room_model = property_model_rooms.build unless room_model

            # extract accessible attributes for the room
            room_attributes = room.inject({}) do |result, (key, value)|
              result[key] = value if room_accessibles.include?(key)
              result
            end

            # update the room model's attributes
            room_model.update_attributes(room_attributes)
          end
        end

        # find & update or build new file attachments
        if Vebra.models[:file]
          file_class = Vebra.models[:file][:class].to_s.camelize.constantize

          # accessible attributes for the files
          file_accessibles = file_class.accessible_attributes.map(&:to_sym)

          # first normalize the collection (currently nested collections)
          property_files = property.attributes[:files].inject([]) do |result, (kind, collection)|
            collection.each do |file|
              file[:type] = kind.to_s.singularize.camelize if file_accessibles.include?(:type)
              file["remote_#{Vebra.models[:file][:attachment_method]}_url".to_sym] = file.delete(:url)
              # if file[:type] is set, it means the attachment file class can be subclassed. In this
              # case we need to ensure that the subclass exists. If not, we ignore this file
              begin
                file[:type].constantize if file_accessibles.include?(:type)
                result << file
              rescue NameError => e
                # ignore - this means the subclass does not exist
                puts "[Vebra]: #{e.message}" if Vebra.debugging?
              end
            end

            result
          end

          # delete any files which are no longer present
          property_model_files = property_model.send(Vebra.models[:property][:files_method])
          refs_to_delete = property_model_files.map(&:vebra_ref) - property_files.map { |f| f[:vebra_ref] }
          property_model_files.each do |file|
            file.destroy if refs_to_delete.include?(file.vebra_ref)
          end

          # find & update or build new files
          property_files.each do |file|
            begin
              file_model = property_model_files.find_by_vebra_ref(file[:vebra_ref])
              file_model = property_model_files.build unless file_model

              # extract accessible attributes for the file
              file_attributes = file.inject({}) do |result, (key, value)|
                result[key] = value if file_accessibles.include?(key)
                result
              end

              # update the room model's attributes
              file_model.update_attributes(file_attributes)
            rescue CarrierWave::ProcessingError, OpenURI::HTTPError => e
              # just ignore the file
              puts "[Vebra]: #{e.message}" if Vebra.debugging?
            end
          end
        end

        property_model.no_callbacks = false if property_model.respond_to?(:no_callbacks)
        property_model.save
        return property_model
      end

    end
  end
end