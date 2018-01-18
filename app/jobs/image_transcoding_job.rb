# frozen_string_literal: true

# Transcoding job specific to ImageComponents
class ImageTranscodingJob < MediaTranscodingJob

  def perform(component)
    super component
  end

  private

  def store_key
    # array takes on the keys of the "steps" defined below, e.g. %w[image blur thumb]
    %w[image]
  end

  def transcoding_steps(path)
    # steps array are the "step" definitions defined below, e.g. { steps: [import(path), optimize, blur, thumb, store] }
    { steps: [import(path), optimize, store] }
  end

  def optimize
    transloadit_client.step('image', '/image/optimize', {
      progressive: false,
      use: 'import',
      preserve_meta_data: true,
      fix_breaking_images: true,
      result: true
    })
  end

  def blur
    transloadit_client.step('blur', '/image/resize', {
      blur: '200x100',
      use: 'import',
      result: true
    })
  end

  def thumb
    transloadit_client.step('thumb', '/image/resize', {
      width: 100,
      height: 100,
      use: 'import',
      result: true
    })
  end
end
