# frozen_string_literal: true

module V1
  # ComponentCollectionsController
  class ComponentCollectionsController < ApplicationController
    include ComponentsHelper

    def create
      return not_found unless fetch_collectible
      @collection = ComponentCollection.new(component_collection_params)
      @collectible.component_collections << @collection
      authorize @collectible, :add_component?
      complete_create_request(@collection)
      AddPageMetadataJob.perform_later(@collectible.id) if @collectible&.errors && @collectible.errors.empty?
    end

    def show
      complete_show_request(fetch_collection)
    end

    def destroy
      complete_destroy_request(fetch_collection)
      AddPageMetadataJob.perform_later(@collection.collectible.id) if @collection&.collectible.is_a? Page
    end

    def update
      complete_update_request(fetch_collection, update_params)
    end

    def index
      return not_found unless fetch_collectible
      authorize(@collectible, :index_component_collections?)
      complete_index_request(@collectible.component_collections)
    end

    def index_by_user
      render json: component_collections_by_user
    end

    private

    def component_collection_params
      component_collection_payload
    end

    def component_collections_by_user
      ComponentCollection.where(collectible: Page.where(user: params[:user_id], published: true)).includes(:components)
    end

    def update_params
      params = parse_collection_params.delete_if { |key| key == 'type' || key == 'components' }
      params[:collectible] = current_user if unlink_key_present?
      params
    end
  end
end
