# frozen_string_literal: true

#
# A model that represents a type of recognition that an object can receive. May be attributed to any object.
#
class Nod < ApplicationRecord
  belongs_to :user
  belongs_to :noddable, polymorphic: true

  validates_presence_of :user, :noddable
  validates_uniqueness_of :user_id, scope: %i[noddable_id noddable_type]

  scope :by_user, ->(user) { where(user: user) }
end
