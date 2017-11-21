# frozen_string_literal: true

module V1
  # SingleUseComponentCollectionsController
  class SingleUseComponentCollectionsController < ComponentCollectionsController
    include ComponentsHelper

    skip_before_action :authenticate_user!, only: %i[show]
    after_action :allow_iframe, only: :show

    def create
      @collection = ComponentCollection.new(component_collection_payload)
      @collection.collectible = current_user
      complete_create_request(@collection)
    end

    def index
      head(501)
    end

    def show
      complete_show_request(fetch_collection, :show_single_use_collection?)
    end

    private

    def component_collections_by_user
      ComponentCollection
        .where(collectible: Page.where(user: current_user))
        .or(ComponentCollection.where(collectible: current_user)).includes(:components)
    end

    def allow_iframe
      response.headers.except! 'X-Frame-Options'
    end
  end
end
