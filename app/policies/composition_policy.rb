# frozen_string_literal: true

# Composition auth policy
class CompositionPolicy < ApplicationPolicy
  def show?
    record.published? || record.user == user
  end

  def link_page?
    record.user == user
  end

  def unlink_page?
    link_page?
  end
end
