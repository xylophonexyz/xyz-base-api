# frozen_string_literal: true

# Component auth policy
class ComponentPolicy < ApplicationPolicy
  def create?
    component_auth(true)
  end

  def destroy?
    component_auth(true)
  end

  def show?
    component_auth
  end

  def update?
    component_auth(true)
  end

  def upload?
    component_auth(true)
  end

  def transcode?
    component_auth(true)
  end

  private

  def component_auth(strict = false)
    collectible = record.component_collection.collectible
    if publishable?(collectible)
      if strict
        collectible.user == user
      else
        record_is_published?(collectible) || collectible.user == user
      end
    elsif collectible.is_a?(User)
      collectible == user
    end
  end

  def publishable?(record)
    record.respond_to?(:published) || record.respond_to?(:published?) || record.respond_to?(:published_on)
  end

  def record_is_published?(record)
    if record.respond_to?(:published)
      record.published
    elsif record.respond_to?(:published?)
      record.published?
    elsif record.respond_to?(:published_on)
      record.published_on
    else
      false
    end
  end
end
