# frozen_string_literal: true

#
# Made up of many Component objects, allowing us to build up collections such as photo and audio albums,
# playlists, film collections, stories and more
#
# @page_id: reference to the page this ComponentCollection is a part of
# @index: an integer that can be used to determine the index of this collection within a Page
# @type: provides us the ability to discern between collection types, such as a BareCollection
#
class ComponentCollection < ApplicationRecord
  serialize :metadata

  belongs_to :collectible, polymorphic: true
  has_many :components, dependent: :destroy

  accepts_nested_attributes_for :components

  before_save :set_default_values

  private

  def set_default_values
    self.index = 0 if index.nil?
  end
end
