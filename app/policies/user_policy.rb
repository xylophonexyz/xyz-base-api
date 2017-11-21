# frozen_string_literal: true

# User auth policy
class UserPolicy < ApplicationPolicy
  def follow?
    user != record
  end

  def unfollow?
    user != record
  end

  def update?
    user == record
  end

  def update_avatar?
    update?
  end

  def destroy?
    update?
  end
end
