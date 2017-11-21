# frozen_string_literal: true

#
# A MediaComponent allows for uploads, processing, and retrieval of media files, facilitated by <Transloadit>.
#
class MediaComponent < Component
  serialize :media

  before_create :set_media_processing
  before_create :sanitize_media

  def transcoding_job
    # this method must be implemented by the subclass to return the appropriate ApplicationJob subclass
    # what is here is essentially a noop
    ApplicationJob
  end

  private

  # remove file objects or any other types that dont quack like a Hash
  def sanitize_media
    self.media = nil unless media.respond_to? :has_key?
  end

  # file uploads and transcoding occur asynchronously.
  # we set this flag here to let the view layer know there is still work to be done
  def set_media_processing
    self.media_processing = true
  end
end
