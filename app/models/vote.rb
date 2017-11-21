# frozen_string_literal: true

#
# A model that represents user interaction in the form of voting. A Vote can either be voted "up" or "down", where
# those values are mapped to true and false respectively
#
class Vote < ApplicationRecord
  belongs_to :votable, polymorphic: true
  belongs_to :user

  validates_presence_of :user
  validates_presence_of :votable
  validates_uniqueness_of :user_id, scope: %i[votable_id votable_type]

  scope :upvotes, -> { where(value: true) }
  scope :downvotes, -> { where(value: false) }
  scope :by_user, ->(user) { where(user: user) }

  def upvote
    update_attribute(:value, true)
  end

  def downvote
    update_attribute(:value, false)
  end
end
