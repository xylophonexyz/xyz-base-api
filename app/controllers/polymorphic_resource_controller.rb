# frozen_string_literal: true

# Controller with methods specific to resources that are polymorphic within the system
class PolymorphicResourceController < ApplicationController
  private

  def get_parent(id, type)
    klass = type.capitalize.constantize
    @parent = klass.where(id: id).first
  end

  def fail_if_no_parent
    not_found unless get_parent(resource_params[:resource_id], resource_params[:resource_type])
  rescue NameError
    unknown_class
  end

  def resource_params
    # implemented by subclass
  end
end
