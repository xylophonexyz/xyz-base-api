# frozen_string_literal: true

module V1
  # SearchController
  class SearchController < ApplicationController
    skip_before_action :authenticate_user!, only: [:search]

    def search
      render json: { pages: page_search.as_json, users: user_search.as_json }
    end

    def user_search
      resource = user_search_resource
      ActiveModelSerializers::SerializableResource.new(resource, scope: current_user)
    end

    def page_search
      resource = page_search_resource + tag_search_resource
      ActiveModelSerializers::SerializableResource.new(resource)
    end

    def tag_search_resource
      Tag.search(params[:query])
    end

    def page_search_resource
      Page.search(params[:query])
    end

    def user_search_resource
      User.search(params[:query])
    end
  end
end
