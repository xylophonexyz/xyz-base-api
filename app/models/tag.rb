# frozen_string_literal: true

#
# A model that represents a label that can be attributed to some other object
#
class Tag < ApplicationRecord
  has_many :taggings, dependent: :destroy
  has_many :taggables, through: :taggings, source: :taggable

  validates_uniqueness_of :name
  validates :name, format: { with: /\A[a-zA-Z0-9_-]+\Z/ }

  def self.search(query)
    results = []
    where('name like ?', "%#{query}%").includes(taggings: [:taggable]).map do |tag|
      tag.taggings.each do |tagging|
        results << tagging.taggable
      end
    end
    results.uniq
  end

  def self.new(params = {})
    tag = Tag.find_by_name(params[:name])
    tag || super
  end
end
