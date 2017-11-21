# frozen_string_literal: true

# ComponentCollection auth policy
class ComponentCollectionPolicy < ApplicationPolicy
  def create_component?
    component_collection_auth
  end

  def destroy?
    component_collection_auth
  end

  def index_components?
    if record.collectible.respond_to?(:published)
      record.collectible.published || user_is_parent_author?
    elsif record.collectible.is_a?(User)
      parent_is_user?
    end
  end

  def index_component_collections?
    if record.respond_to?(:published)
      record.published || record.user == user
    elsif record.is_a?(User)
      record == user
    end
  end

  def update?
    component_collection_auth
  end

  def show_single_use_collection?
    if record.collectible.is_a? User
      true
    elsif record.collectible.is_a? Page
      record.collectible.published || (user == record.collectible.user)
    else
      false
    end
  end

  private

  def component_collection_auth
    if record.collectible.respond_to?(:user)
      user_is_parent_author?
    elsif record.collectible.is_a?(User)
      parent_is_user?
    end
  end

  def user_is_parent_author?
    user == record.collectible.user
  end

  def parent_is_user?
    user == record.collectible
  end
end
