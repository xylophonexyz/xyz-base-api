# frozen_string_literal: true

#
# A simple record that represents "touching" some other object, typically by visiting a page or accessing a resource
#
class View < ApplicationRecord
  belongs_to :user
  belongs_to :viewable, polymorphic: true
  validates_presence_of :user, :viewable
end
