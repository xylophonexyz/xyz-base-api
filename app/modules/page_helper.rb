# frozen_string_literal: true

# Helper for Page related logic
module PageHelper
  def guess_title(object)
    title = object.title
    text_helper = ActionController::Base.helpers
    object.components.each do |collection|
      media = collection.components.first.media unless collection.components.empty?
      title = media if media.is_a?(String)
    end
    text_helper.truncate(text_helper.strip_tags(title), length: 140)
  end

  def cover(object)
    photo = nil
    object.components.each do |collection|
      break if photo
      collection.components.each { |component| photo = media_url(component) if media_component?(component) }
    end
    photo
  rescue StandardError
    photo
  end

  private

  def media_component?(component)
    component.is_a?(ImageComponent) || component.is_a?(VideoComponent) ||
      component.is_a?(AudioComponent) || component.is_a?(MediaComponent)
  end

  def media_url(component)
    media = ActiveModelSerializers::SerializableResource.new(component).as_json[:media] || {}
    media[:poster] || media[:url]
  end
end
