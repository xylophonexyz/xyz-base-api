# frozen_string_literal: true

module V1
  # UsersController
  class UsersController < ApplicationController
    before_action only: %i[email create] do
      doorkeeper_authorize! ENV['SU_SCOPE']
    end
    skip_before_action :authenticate_user!, only: %i[create check show email]

    def check
      if params[:email]
        @user = User.find_by_email params[:email]
      elsif params[:username]
        @user = User.find_by_username params[:username]
      end
      status = @user ? :ok : :not_found
      head(status)
    end

    def create
      @user = User.new params.permit(:email)
      complete_create_request(@user)
    end

    def me
      render json: current_user
    end

    def show
      complete_show_request(fetch_user)
    end

    def email
      # admin level api call -- send an email to any user in the system
      return not_found unless params[:email]
      mailer_opts = {
        address: params[:email],
        subject: params[:subject],
        template: params[:template],
        client_app: client_app&.name
      }
      AdminMailer.send_email(mailer_opts).deliver_later
    end

    def follow
      return not_found unless fetch_user
      authorize @user
      return head(:conflict) if current_user.following?(@user)
      current_user.follow @user
      render json: @user, status: :ok
    end

    def unfollow
      return not_found unless fetch_user
      authorize @user
      return head(:conflict) unless current_user.following?(@user)
      current_user.unfollow @user
      render json: @user
    end

    def update
      @user ||= current_user
      add_metadata(@user)
      complete_update_request(@user, user_params)
    end

    def update_avatar
      return unauthorized unless @user ||= current_user
      authorize @user
      @user.avatar = params[:image_data_url] ? StringIO.new(params[:image_data_url]).read : nil
      complete_save_request(@user)
    end

    def destroy
      @user ||= current_user
      complete_destroy_request(@user)
    end

    private

    def fetch_user
      id = params[:id] || params[:user_id]
      query = query_from_params(id)
      query = add_includes_to_query(query)
      @user = query.first
    end

    def query_from_params(id)
      if params[:use_username]
        User.where(username: id)
      elsif params[:use_id]
        User.where(id: id)
      else
        User.where(id: id).or(User.where(username: id))
      end
    end

    def add_includes_to_query(query)
      query.includes(compositions: [pages: [:views, :tags, nods: [:user], votes: [:user]]])
    end

    def user_params
      params.permit(:first_name, :last_name, :email, :bio, :username, :onboarded)
    end

    def add_metadata(user)
      return unless user
      metadata = params[:metadata] || {}
      metadata = metadata.permit! if metadata.respond_to? :permit!
      user.metadata ||= {}
      user.metadata = user.metadata.to_h.merge(metadata.to_h)
    end
  end
end
