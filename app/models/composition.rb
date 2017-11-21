# frozen_string_literal: true

#
# A general purpose container model that holds references to Pages, and other Compositions as children. In
# addition, tags and a single cover image are possible associations.
#
class Composition < ApplicationRecord
  serialize :metadata

  belongs_to :user
  belongs_to :parent, class_name: 'Composition'
  has_many :compositions, foreign_key: :parent_id
  has_many :pages, dependent: :destroy
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings
  has_one :image, as: :collectible, class_name: 'ComponentCollection', foreign_key: :collectible_id

  validates_presence_of :user
  validates_presence_of :title
  validate :validate_circular_reference

  def cover
    image&.components&.first
  end

  def published?
    !published_on.nil?
  end

  private

  def validate_circular_reference
    errors.add(:parent, 'Attempted to set a circular reference') if parent == self
  end
end
