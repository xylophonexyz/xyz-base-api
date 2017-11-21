# frozen_string_literal: true

module V1
  # CompositionsController
  class CompositionsController < ApplicationController
    include ActionView::Helpers::SanitizeHelper
    include CompositionsControllerHelper
    include ComponentsHelper

    before_action :sanitize_params, only: %i[create update]
    skip_before_action :authenticate_user!, only: %i[index index_by_user show download]
    before_action only: [:download] do
      doorkeeper_authorize! ENV['SU_SCOPE']
    end

    def create
      @composition = Composition.new(composition_params.merge(user: current_user))
      publish_composition(save: false) if should_publish?
      add_parent if should_add_parent?
      add_cover_image if should_add_cover_image?
      complete_create_request(@composition)
    end

    def index
      complete_index_request(Composition.where.not(published_on: nil).includes(:pages))
    end

    def show
      complete_show_request(fetch_composition)
    end

    def destroy
      complete_destroy_request(fetch_composition)
    end

    def download
      # this is an admin level api method - drafts and published compositions can be bundled by
      # those possessing an SU_SCOPE level auth scope. these are generally trusted clients (gateway, internal apps, etc)
      return not_found unless fetch_composition
      render json: { files: file_bundle_from_composition(@composition) }
    end

    def index_by_current_user
      # return all pages (published and drafts) for the current user
      complete_index_request(Composition.where(user: current_user).includes(:pages))
    end

    def index_by_user
      # return all published pages for a given user
      complete_index_request(Composition.where(user: params[:user_id]).where.not(published_on: nil).includes(:pages))
    end

    def link_page
      return not_found unless fetch_composition && fetch_page
      authorize_with_policy(:link_page?)
      @composition.pages << @page
      return render json: { errors: record.errors }, status: :bad_request unless @page.save
      complete_save_request(@composition)
    end

    def unlink_page
      return not_found unless fetch_composition && fetch_page
      authorize_with_policy(:unlink_page?)
      return render json: { errors: @page.errors }, status: :bad_request unless should_unlink?
      @page.composition_id = nil
      return render json: { errors: record.errors }, status: :bad_request unless @page.save
      complete_save_request(@composition)
    end

    def update
      return not_found unless fetch_composition
      publish_composition(save: false, value: ActiveRecord::Type::Boolean.new.deserialize(params[:publish]))
      perform_update_tasks
      complete_update_request(@composition, composition_params)
    end

    private

    def authorize_with_policy(method)
      raise Pundit::NotAuthorizedError unless CompositionPolicy.new(current_user, @page).send(method)
    end
  end
end
