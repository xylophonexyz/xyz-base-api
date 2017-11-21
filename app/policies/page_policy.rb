# frozen_string_literal: true

# Page auth policy
class PagePolicy < ApplicationPolicy
  def add_component?
    user == record.user
  end

  def index_component_collections?
    record.published || record.user == user
  end

  def show?
    record.published || record.user == user
  end
end
