# frozen_string_literal: true

#
# An AudioComponent allows for uploads, processing, and retrieval of audio files.
#
class AudioComponent < MediaComponent
  def transcoding_job
    AudioTranscodingJob
  end
end
