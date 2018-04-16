# frozen_string_literal: true

module V1
  # PagesController
  class PagesController < ApplicationController
    include ActionView::Helpers::SanitizeHelper

    before_action :fetch_tags, only: %i[create update]
    before_action :validate_billing_account!, only: %i[create update]
    before_action :sanitize_params, only: %i[create update]
    skip_before_action :authenticate_user!, only: %i[index index_by_featured index_by_user show]
    after_action :increment_view_count, only: %i[show]
    after_action :update_billing_account, only: %i[create destroy]

    def create
      @page = Page.new page_params.merge(user: current_user)
      add_tags(@page, fetch_tags)
      complete_create_request(@page)
    end

    def show
      complete_show_request(fetch_page)
    end

    def destroy
      complete_destroy_request(fetch_page)
    end

    def index
      @pages = page_query published: true
      render json: @pages, each_serializer: PagePreviewSerializer
    end

    def index_by_current_user
      @pages = index_pages_by_params
      render json: @pages, each_serializer: PagePreviewSerializer
    end

    def index_by_featured
      @pages = page_query published: true
      render json: @pages.sort_by(&:rating), each_serializer: PagePreviewSerializer
    end

    def index_by_following
      @pages = get_following_pages current_user
      render json: @pages, each_serializer: PagePreviewSerializer
    end

    def index_by_user
      @pages = filter_pages_by_user params[:user_id]
      render json: @pages, each_serializer: PagePreviewSerializer
    end

    def update
      add_tags(fetch_page, fetch_tags)
      complete_update_request(@page, page_params)
      AddPageMetadataJob.perform_later @page.id if @page.errors.empty?
    end

    private

    def add_tags(page, tags)
      page.tags = tags
    end

    def all_by_current_user
      @pages = page_query user: current_user
    end

    def drafts_by_current_user
      @pages = page_query published: false, user: current_user
    end

    def filter_pages_by_user(id)
      page_query user: id, published: true
    end

    def index_pages_by_params
      if params[:published] == 'published'
        published_by_current_user
      elsif params[:published] == 'drafts'
        drafts_by_current_user
      else
        all_by_current_user
      end
    end

    def get_following_pages(user)
      pages = []
      return pages unless user
      user.following.each { |u| pages << page_query(user: u) }
      pages.flatten
    end

    def fetch_page
      @page = page_query(id: params[:id]).first
    end

    def fetch_tags
      @tags = (params[:tags] || []).map do |t|
        name = t.tr(' ', '_').chomp.downcase
        name = name.gsub(/[^a-zA-Z.-_ ]/, '')
        Tag.new(name: name)
      end
    end

    def increment_view_count
      @page.views << View.new(user: current_user, viewable: @page)
      @page.save
    end

    def published_by_current_user
      @pages = page_query(published: true, user: current_user)
    end

    def page_query(params)
      page_query_includes Page.where(params)
    end

    def page_query_includes(query)
      query.includes(:views, :tags, nods: [:user], votes: [:user], component_collections: [:components])
    end

    def sanitize_params
      # avoid overriding the existing model value on update by sanitizing only if the key is present in params
      params[:title] = strip_tags params[:title] if params.key? :title
      params[:description] = strip_tags params[:description] if params.key? :description
    end

    def page_params
      params.permit(:title, :description, :published, :composition_id, :metadata).merge(metadata_params)
    end

    def metadata_params
      { metadata: params.permit![:metadata] } unless params[:metadata].nil?
    end
  end
end
