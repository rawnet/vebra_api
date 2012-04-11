module Vebra
  module Bridge

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      # acts_as_vebra allows the gem to handle translating the initial
      # loose Vebra models (eg Property) into ActiveRecord models with
      # associations

      # valid attributes are determined using attr_accessible and associations;
      # if an attribute or association doesn't exist, it will be ignored

      def acts_as_vebra(vebra_model=nil, options={})
        vebra_model = self.to_s.underscore.to_sym unless vebra_model
        puts "[Vebra]: acting as :#{vebra_model}" if Vebra.debugging?
        Vebra.models[vebra_model.to_sym] = options.merge(:model_class => self)
      end

    end

  end
end