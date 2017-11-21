# frozen_string_literal: true

# JSON serializer for Page objects
class PageSerializer < PagePreviewSerializer
  attributes :tags

  has_many :components

  def tags
    object.tags.map(&:name)
  end
end
