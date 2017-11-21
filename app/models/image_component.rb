# frozen_string_literal: true

#
# An ImageComponent allows for uploads, processing, and retrieval of image files
#
class ImageComponent < MediaComponent
  def transcoding_job
    ImageTranscodingJob
  end
end
