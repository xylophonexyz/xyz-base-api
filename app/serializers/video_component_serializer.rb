# frozen_string_literal: true

# JSON serializer for VideoComponent objects
class VideoComponentSerializer < MediaComponentSerializer
  # print the most commonly used url for the media as a convenience for the consumer
  def convenience_url
    media = base_convenience_path
    { url: media['hd'][0]['url'], poster: media['thumbs'][0]['url'] }
  rescue StandardError
    super
  end
end
