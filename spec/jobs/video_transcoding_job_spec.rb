require 'rails_helper'
require "stubs/transloadit_stub"

RSpec.describe VideoTranscodingJob, type: :job do

  include_context 'transloadit stub'

  before :each do
    stub_all_transloadit_calls
  end

  it 'should process a video file' do
    video = VideoComponent.new(media: {
      # this key is not guaranteed to exist, but it has a very high likelihood of existing
      upload: { key: 'test/components/1/file.MOV' }
    })
    collection = ComponentCollection.new(components: [video])
    collection.save

    expect(video[:transcoding]).to be_nil

    VideoTranscodingJob.perform_now(video.id)

    expect(video.reload.media[:transcoding]).to_not be_nil
  end
end
