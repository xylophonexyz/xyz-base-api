# frozen_string_literal: true

#
# A VideoComponent allows for uploads, processing, and retrieval of video files
#
class VideoComponent < MediaComponent
  def transcoding_job
    VideoTranscodingJob
  end
end
