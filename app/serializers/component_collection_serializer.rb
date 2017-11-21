# frozen_string_literal: true

# JSON serializer for ComponentCollection objects
class ComponentCollectionSerializer < ApplicationSerializer
  attributes :id, :type, :metadata, :index, :components, :collectible_id, :collectible_type, :created_at, :updated_at

  def components
    object.components.map do |component|
      resource_class_name = component.class.name.demodulize
      serializer_class_name = "#{resource_class_name}Serializer"
      serializer = serializer_class_name.safe_constantize || ComponentSerializer
      serializer.new(component, scope: scope, root: false, event: object)
    end
  end
end
