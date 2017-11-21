require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe AddPageMetadataJob, type: :job do

  let(:user) { double :acceptable? => true }
  let(:token) { double :acceptable? => true }

  it 'should add metadata to a page' do
    text_collection = ComponentCollection.new
    image_collection = ComponentCollection.new
    text_collection.components << Component.new(media: 'Foo Bar')
    image = new_image_component
    image.media = { url: 'http://example.com/1/2/3' }
    image_collection.components << image
    page = new_page
    page.components << text_collection
    page.components << image_collection
    page.save
    AddPageMetadataJob.perform_now(page.id)
    expect(page.reload.metadata).to_not be_nil
    expect(page.metadata[:guessed_title]).to_not be_nil
    expect(page.metadata[:cover]).to_not be_nil
  end
end
