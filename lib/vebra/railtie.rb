require 'rails'

module Vebra
  class Railtie < Rails::Railtie
    railtie_name :vebra

    rake_tasks do
      load "tasks/update_properties.rake"
    end
  end
end