# frozen_string_literal: true

# Helper for Page related logic
module PageHelper
  def guess_title(object)
    title = (object.title || object.description || '').strip
    if title == ''
      object.components.each do |collection|
        media = collection.components.first.media unless collection.components.empty?
        title = media if media.is_a?(String)
      end
      sorted_text_blacklist.each { |artifact| title = title.gsub(artifact, '') }
    end
    ActionController::Base.helpers.truncate(ActionController::Base.helpers.strip_tags(title), length: 140).strip
  end

  def cover(object)
    photo = nil
    object.components.each do |collection|
      break if photo
      collection.components.each { |component| photo = media_url(component) if has_thumbnail?(component) }
    end
    photo
  rescue StandardError
    photo
  end

  private

  def sorted_text_blacklist
    [/\\n/, /[^\w\s]/, /(opsinsert)/]
  end

  def has_thumbnail?(component)
    component.is_a?(ImageComponent) || component.is_a?(VideoComponent)
  end

  def media_component?(component)
    component.is_a?(ImageComponent) || component.is_a?(VideoComponent) ||
      component.is_a?(AudioComponent) || component.is_a?(MediaComponent)
  end

  def media_url(component)
    media = ActiveModelSerializers::SerializableResource.new(component).as_json[:media] || {}
    media[:poster] || media[:url]
  end
end
