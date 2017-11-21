require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe ComponentCollection, type: :model do

  let(:tl_response) { double(:tl_response) }

  before(:each) do
    @collection = ComponentCollection.create!
    @bare_collection = ComponentCollection.create!
    @audio_collection = ComponentCollection.create!
    @image_collection = ComponentCollection.create!
    @video_collection = ComponentCollection.create!
    @component = Component.new
    @audio_component = AudioComponent.new
    @image_component = ImageComponent.new
    @video_component = VideoComponent.new
    @text_component = Component.new
    @spacer_component = Component.new
  end

  describe 'General' do

    it 'should create a component collection' do
      expect(@collection).to be_valid
    end

    it 'should allow addition of free form data to component collection model' do
      @collection.metadata = { foo: 'bar', baz: 'qux', foobar: [1, 2, 3] }
      @collection.save!
      expect(@collection.reload.metadata).to eql({ foo: 'bar', baz: 'qux', foobar: [1, 2, 3] })
    end

    it 'should create a component collection with default values' do
      expect(@collection.index).to eq(0)
    end

    it 'should support the addition of new components into the collection' do
      @collection.components << @component
      @collection.components << new_audio_component
      @collection.components << new_image_component
      @collection.components << new_video_component
      @collection.save!
      expect(Component.all.length).to eq(4)
      expect(ComponentCollection.all.length).to eq(5)
    end

    it 'should destroy a component collection' do
      @collection.destroy
      expect(ComponentCollection.all.length).to eq(4)
    end

    it 'should destroy a component collection when the associated belongs_to model is destroyed' do
      page = Page.new(user: new_user)
      page.component_collections << @collection
      page.save!
      page.destroy
      expect(ComponentCollection.all.length).to eq(4)
    end

    it 'should destroy components when the associated collection has been destroyed' do
      @collection.components << @component
      @collection.components << new_audio_component
      @collection.components << new_image_component
      @collection.components << new_video_component
      @collection.save!
      @collection.destroy
      expect(Component.all.length).to eq(0)
    end

    it 'should associate a component collection with any object' do
      # in this example an ComponentCollection is created and is associated with an ComponentCollection as
      # its 'collectible' object. this is a real world example where an ComponentCollection has a set of images that are
      # part of the experience of the collection. the image collection is stored in the ComponentCollection's metadata
      # attribute.
      @image_collection = ComponentCollection.new
      @image_collection.components << new_image_component
      @image_collection.components << new_image_component

      @collection = ComponentCollection.new
      @collection.components << new_audio_component
      @collection.components << new_audio_component

      @image_collection.collectible = @collection
      @image_collection.save!
      @collection.save!

      @collection.update(metadata: {
        image_collection: @image_collection.as_json(include: :components).as_json
      })

      expect(@image_collection.reload.collectible.id).to eq(@collection.reload.id)
      expect(@collection.metadata[:image_collection]['collectible_type'])
        .to eq(@image_collection.reload.as_json(include: :components)
                 .as_json['collectible_type'])
      expect(@collection.metadata[:image_collection]['components'][0]['media']).to be_nil
      expect(@collection.metadata[:image_collection]['components'][0]['media_processing']).to eq(true)
    end

  end
end
