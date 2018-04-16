# frozen_string_literal: true

# Helper for Page related logic
module PageHelper
  def guess_title(object)
    title = (object.title || object.description || '').strip
    if title == ''
      page_index = object.user.pages.sort_by(&:created_at).index { |p| p.id == object.id }
      title = "Page #{page_index + 1}"
    end
    title
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
