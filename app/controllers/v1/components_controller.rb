# frozen_string_literal: true

module V1
  # ComponentsController
  class ComponentsController < ApplicationController
    include ComponentsHelper
    include UploadHelper
    include TransloaditNotificationsHelper

    before_action :filename, only: [:upload]
    before_action :validate_billing_account!, only: %i[create update]
    skip_before_action :authenticate_user!, only: [:notify]
    skip_before_action :doorkeeper_authorize!, only: [:notify]
    skip_before_action :set_current_user, only: [:notify]
    after_action :update_billing_account, only: %i[create update destroy]

    def create
      return not_found unless fetch_collection
      @component = Component.new(component_params)
      @component.component_collection = @collection
      complete_create_request(@component)
    end

    def destroy
      complete_destroy_request(fetch_component)
    end

    def index
      return not_found unless fetch_collection
      authorize @collection, :index_components?
      render json: components_by_collection
    end

    def show
      complete_show_request(fetch_component)
    end

    def update
      complete_update_request(fetch_component, update_params)
    end

    def notify
      return unauthorized unless verified_signature?
      return bad_request unless fetch_component
      initiate_transcoding_job(2.seconds)
      head :ok
    end

    def transcode
      return not_found unless fetch_component && @component.component_collection
      authorize @component
      initiate_transcoding_job
    end

    def upload
      return handle_upload_request_error unless fetch_component && validate_params_for_upload
      authorize @component
      process_upload_for_component
      render json: @component if @component.save
    end

    private

    def component_params
      component_payload
    end

    def initiate_transcoding_job(wait = 0.seconds)
      @component.transcoding_job.set(wait: wait).perform_later @component.id
    end

    def components_by_collection
      Component.where(component_collection: @collection)
    end

    def filename
      @filename_for_upload = params[:filename]
      render json: { errors: 'Filename is required' }, status: 400 unless @filename_for_upload
    end

    def update_params
      whitelist = @component.is_a?(MediaComponent) ? %w[type media] : %w[type]
      parse_component_params.delete_if { |key| whitelist.include? key }
    end
  end
end
