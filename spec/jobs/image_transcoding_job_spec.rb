require 'rails_helper'
require "stubs/transloadit_stub"

RSpec.describe ImageTranscodingJob, type: :job do

  include_context 'transloadit stub'

  before :each do
    stub_all_transloadit_calls
  end

  it 'should process an image by optimizing the file and uploading it to s3' do
    image = ImageComponent.new(media: {
      # this key actually does exist, but we use stubs in testing anyway
      upload: { key: 'test/components/1/file.png' }
    })
    collection = ComponentCollection.new(components: [image])
    collection.save

    expect(image[:transcoding]).to be_nil

    ImageTranscodingJob.perform_now(image.id)

    expect(image.reload.media[:transcoding]).to_not be_nil
  end
end
