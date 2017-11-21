# frozen_string_literal: true

#
# A join between tags and the objects they are representing
#
class Tagging < ApplicationRecord
  belongs_to :tag
  belongs_to :taggable, polymorphic: true
end
