require 'rails_helper'
require "stubs/transloadit_stub"

RSpec.describe AudioTranscodingJob, type: :job do

  include_context 'transloadit stub'

  before :each do
    stub_all_transloadit_calls
  end

  it 'should process an audio file by creating wav and mp3 versions' do
    audio = AudioComponent.new(media: {
      # this key is not guaranteed to exist, but it has a very high likelihood of existing
      upload: { key: 'test/components/1/file.m4a' }
    })
    collection = ComponentCollection.new(components: [audio])
    collection.save

    expect(audio[:transcoding]).to be_nil

    AudioTranscodingJob.perform_now(audio.id)

    expect(audio.reload.media[:transcoding]).to_not be_nil
  end
end
