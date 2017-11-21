# frozen_string_literal: true

# Helper for OAuth related logic
module SessionHelper
  def client_is_valid?(uid, secret)
    Doorkeeper::Application.by_uid_and_secret(uid, secret)
  end

  def user_by_email(email)
    User.where(email: email).first
  end

  def client_app
    pre_auth&.client&.application
  end
end
