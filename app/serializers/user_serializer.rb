# frozen_string_literal: true

# JSON serializer for User objects
class UserSerializer < ApplicationSerializer
  attributes :id, :email, :bio, :first_name, :last_name, :username, :created_at
  attributes :followers, :following
  attributes :metadata, :type, :onboarded
  attributes :session, :avatar
  attributes :billing_account

  def session
    { is_following: scope&.following?(object) }
  end

  def avatar
    { url: object.avatar }
  end
end
