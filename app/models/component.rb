# frozen_string_literal: true

#
# Part of a ComponentCollection.
# Holds a reference to media, handles upload, processing, and retrieval of media.
#
# @component_collection_id: parent ComponentCollection
# @media: a text string holding the media itself, a json object containing the url to the media held elsewhere, or nil
# @type: provides us the ability to discern between component types, such as audio, image, video, text, etc
# @index: an integer that can be used to determine the index of a Component within a ComponentCollection
# @metadata: free form JSON that can be used to store metadata that may not be common among other Components
#
class Component < ApplicationRecord
  serialize :metadata

  belongs_to :component_collection

  before_save :set_default_values

  private

  def set_default_values
    self.index = 0 if index.nil?
  end
end
