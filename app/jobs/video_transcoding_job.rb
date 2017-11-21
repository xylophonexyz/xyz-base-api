# frozen_string_literal: true

# Transcoding job specific to VideoComponents
class VideoTranscodingJob < MediaTranscodingJob

  def perform(component)
    super(component)
  end

  private

  def store_key
    %w(sd hd thumbs)
  end

  def transcoding_steps(path)
    { steps: [import(path), encode_sd, encode_hd, thumbs, store] }
  end

  def encode_hd
    transloadit_client.step('hd', '/video/encode', {
      use: 'import',
      preset: 'android',
      result: 'true',
      ffmpeg_stack: 'v2.2.3',
      width: '${file.meta.width}',
      height: '${file.meta.height}',
      ffmpeg: {
        'b:v': '${file.meta.video_bitrate}',
        'maxrate': '${file.meta.video_bitrate}',
        'bufsize': '${file.meta.video_bitrate}',
        'r': '${file.meta.framerate}',
        'ar': '${file.meta.audio_samplerate}',
        'b:a': '${file.meta.audio_bitrate}',
        'preset': 'slow'
      }
    })
  end

  def encode_sd
    transloadit_client.step('sd', '/video/encode', {
      use: 'import',
      preset: 'ipad-high',
      width: 1920,
      height: 1080,
      ffmpeg_stack: 'v2.2.3',
      ffmpeg: {
        'map': ['0', '-0:d', '-0:s'],
        'c:v': 'libx264',
        'c:a': 'libfdk_aac',
        'f': 'mp4',
        'pix_fmt': 'yuv420p',
        'r': '${file.meta.framerate}',
        's': '1920x1080',
        'crf': 28,
        'g': 30,
        'b:v': '${file.meta.video_bitrate}',
        'maxrate': '${file.meta.video_bitrate}',
        'bufsize': '${file.meta.video_bitrate}',
        'b:a': 256000,
        'ac': 2,
        'ar': '${file.meta.audio_samplerate}',
        'profile:v': 'high',
        'level:v': '4.0',
        'preset': 'slow'
      }
    })
  end

  def thumbs
    transloadit_client.step('thumbs', '/video/thumbs', {
      use: 'hd',
      count: 10,
      width: 1920,
      height: 1080,
      resize_strategy: 'fit',
      ffmpeg_stack: 'v2.2.3'
    })
  end
end
