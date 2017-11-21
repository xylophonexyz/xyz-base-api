# frozen_string_literal: true

# JSON serializer for MediaComponents
class MediaComponentSerializer < ComponentSerializer
  def media
    object.media.merge(transcoding_attributes).merge(convenience_url).merge(upload_attributes)
  rescue StandardError
    nil
  end

  def base_convenience_path
    JSON.parse(object.media[:transcoding])['results']
  end

  def convenience_url
    # subclasses must implement this method
    { url_parse_error: 'Error reading url' }
  end

  def transcoding_attributes
    { transcoding: base_convenience_path }
  rescue StandardError
    {}
  end

  def upload_attributes
    { upload: object.media[:upload] }
  rescue StandardError
    {}
  end
end
