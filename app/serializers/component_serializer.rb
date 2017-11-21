# frozen_string_literal: true

# JSON serializer for Component objects
class ComponentSerializer < ApplicationSerializer
  attributes :id, :type, :media, :media_processing, :index,
             :metadata, :component_collection_id, :created_at, :updated_at
end
