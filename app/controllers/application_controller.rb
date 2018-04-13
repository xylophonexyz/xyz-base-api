# frozen_string_literal: true

# Top level controller for API requests
class ApplicationController < ActionController::API
  include Pundit
  include BillingHelper

  before_action :doorkeeper_authorize!
  before_action :set_current_user
  before_action :authenticate_user!

  # pundit unauthorized errors return 403 forbidden
  rescue_from Pundit::NotAuthorizedError, with: :forbidden

  private

  def complete_index_request(records, auth_query = :index?)
    return not_found unless records
    authorize(records, auth_query)
    render json: records
  end

  def complete_save_request(record)
    return render json: { errors: record.errors }, status: :bad_request unless record.save
    render json: record
  end

  def complete_create_request(record, auth_query = :create?)
    complete_update_request(record, {}, :save, :created, auth_query)
  end

  def complete_update_request(record, parameters = {}, method = :update, status = :ok, auth_query = :update?)
    return not_found unless record
    authorize(record, auth_query)
    return render json: { errors: record.errors }, status: :bad_request unless record.send(method, parameters)
    render json: record, status: status
  end

  def complete_destroy_request(record, auth_query = :destroy?)
    return not_found unless record
    authorize(record, auth_query)
    return render json: { errors: record.errors }, status: :bad_request unless record.destroy
    head(:ok)
  end

  def complete_show_request(record, auth_query = :show?)
    return not_found unless record
    authorize(record, auth_query)
    render json: record
  end

  def validate_billing_account!
    forbidden(['Inactive, past due, or invalid billing account']) unless valid_billing_account?
  end

  def update_billing_account
    update_user_billing
  end

  def authenticate_user!
    unauthorized unless set_current_user!
  end

  def current_user
    if Thread.current[:current_user]
      Thread.current[:current_user]
    else
      set_current_user
    end
  end

  def set_current_user
    Thread.current[:current_user] = User.where(id: doorkeeper_token.resource_owner_id).first
  end

  def set_current_user!
    Thread.current[:current_user] = User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end

  def forbidden(errors = ['Forbidden'])
    render json: { errors: errors }, status: :forbidden
  end

  def not_found(errors = ['Record not found'])
    render json: { errors: errors }, status: :not_found
  end

  def unauthorized(errors = ['Unauthorized'])
    render json: { errors: errors }, status: :unauthorized
  end

  def unknown_class(errors = ['Unknown class'])
    render json: { errors: errors }, status: :bad_request
  end
end
