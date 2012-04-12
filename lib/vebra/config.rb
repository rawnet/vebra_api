module Vebra
  class << self

    def client
      Config.client
    end

    def debugging?
      Config.debugging?
    end

    def tmp_dir
      Config.tmp_dir
    end

    def models
      Config.model_config
    end

  end

  module Config
    class << self

      @@client_username = nil
      @@client_password = nil
      @@client_data_feed_id = nil
      @@debug_mode = false
      @@tmp_dir = defined?(Rails) ? Rails.root.join('tmp') : nil
      @@models = {
        :property => { :class => :property, :files_method => :files, :address_method => :address, :rooms_method => :rooms },
        :address  => { :class => :address },
        :room     => { :class => :room },
        :file     => { :class => :file, :attachment_method => :attachment }
      }

      def client
        @@client ||= nil
      end

      def debugging?
        @@debug_mode
      end

      def tmp_dir
        @@tmp_dir
      end

      def model_config
        @@models
      end

      def create_client_when_possible
        if @@client_username && @@client_password && @@client_data_feed_id
          @@client = Vebra::Client.new(
            :username => @@client_username,
            :password => @@client_password,
            :data_feed_id => @@client_data_feed_id
          )
        end
      end

      def client_username=(username)
        @@client_username = username
        create_client_when_possible
      end

      def client_password=(password)
        @@client_password = password
        create_client_when_possible
      end

      def client_data_feed_id=(data_feed_id)
        @@client_data_feed_id = data_feed_id
        create_client_when_possible
      end

      def debug=(true_or_false)
        @@debug_mode = true_or_false
      end

      def tmp_dir=(dir_path)
        @@tmp_dir = dir_path
      end

      def models
        Models
      end

    end

    module Models
      class << self

        def property_class=(class_sym)
          Config.model_config[:property][:class] = class_sym
        end

        def address_class=(class_sym)
          Config.model_config[:address][:class] = class_sym
        end

        def room_class=(class_sym)
          Config.model_config[:room][:class] = class_sym
        end

        def file_class=(class_sym)
          Config.model_config[:file][:class] = class_sym
        end

        def file_attachment_method=(method_sym)
          Config.model_config[:file][:attachment_method] = method_sym
        end

        def property_files_method=(method_sym)
          Config.model_config[:property][:files_method] = method_sym
        end

        def property_rooms_method=(method_sym)
          Config.model_config[:property][:rooms_method] = method_sym
        end

        def property_address_method=(method_sym)
          Config.model_config[:property][:address_method] = method_sym
        end

      end
    end
  end
end