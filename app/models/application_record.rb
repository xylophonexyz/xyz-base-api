# frozen_string_literal: true

# Base model to inherit from
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
