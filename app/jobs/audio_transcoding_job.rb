# frozen_string_literal: true

# Transcoding job specific to AudioComponents
class AudioTranscodingJob < MediaTranscodingJob

  def perform(component)
    @component = component
    super(component)
  end

  private

  def store_key
    %w(mp3 flac aac)
  end

  def transcoding_steps(path)
    { steps: [import(path), encode_mp3, encode_flac, encode_aac, write_metadata, store] }
  end

  def encode_flac
    transloadit_client.step('flac', '/audio/encode', {
      use: 'import',
      preset: 'flac',
      ffmpeg_stack: 'v2.2.3',
      result: true
    })
  end

  def encode_aac
    transloadit_client.step('aac', '/audio/encode', {
      use: 'import',
      preset: 'aac',
      ffmpeg_stack: 'v2.2.3',
      bitrate: 320000,
      result: true
    })
  end

  def encode_mp3
    transloadit_client.step('mp3_encode', '/audio/encode', {
      use: 'import',
      preset: 'mp3',
      ffmpeg_stack: 'v2.2.3',
      bitrate: 320000,
      result: true
    })
  end

  def write_metadata
    transloadit_client.step('mp3', '/meta/write', {
      use: 'mp3_encode',
      ffmpeg_stack: 'v2.2.3',
      result: true,
      data_to_write: mp3_metadata
    })
  end

  def mp3_metadata
    meta = { publisher: 'Xylophone', title: '${file.name}' }
    page = @component.component_collection.collectible
    composition = @component.component_collection.collectible.composition
    meta[:album] = album_name(composition)
    meta[:artist] = artist_name(page)
    meta[:album_artist] = album_artist_name(page)
    meta[:track] = track_number(@component)
    meta
  rescue
    meta
  end

  def artist_name(page)
    name = page.user.first_name.to_s
    if page.user.last_name
      name += ' ' + page.user.last_name.to_s
    end
    name
  end

  def album_artist_name(page)
    page.user.username
  end

  def album_name(composition)
    composition.title
  end

  def track_number(component)
    list_length = component.component_collection.components.where(type: 'AudioComponent').length
    "#{component.index + 1}/#{list_length}"
  end
end
