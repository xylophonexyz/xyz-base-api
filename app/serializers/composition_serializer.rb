# frozen_string_literal: true

# JSON serializer for Composition objects
class CompositionSerializer < ApplicationSerializer
  attributes :id, :title, :cover, :published_on, :published, :updated_at, :created_at, :metadata
  attribute :errors, if: :errors?
  belongs_to :user
  belongs_to :parent, serializer: CompositionSerializer
  has_many :compositions, serializer: CompositionSerializer

  # scope pages to only those that are published when the current user is not requesting
  attribute :pages, serializer: PagePreviewSerializer, &:serve_authorized_pages
  has_many :pages, serializer: PagePreviewSerializer, &:serve_authorized_pages

  def cover
    ActiveModelSerializers::SerializableResource.new(object.cover).as_json
  end

  def errors?
    object.errors
  end

  def published
    object.published?
  end

  def serve_authorized_pages
    if object.user == scope
      object.pages
    else
      object.pages.where(published: true)
    end
  end
end
