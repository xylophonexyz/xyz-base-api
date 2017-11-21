# frozen_string_literal: true

# JSON serializer for ImageComponents
class ImageComponentSerializer < MediaComponentSerializer
  # print the most commonly used url for the media as a convenience for the consumer
  def convenience_url
    { url: base_convenience_path['image'][0]['url'] }
  rescue StandardError
    super
  end
end
