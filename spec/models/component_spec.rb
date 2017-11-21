require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe Component, type: :model do

  let(:tl_response) { double(:tl_response) }

  before(:each) do
    @collection = ComponentCollection.create!
    @component = Component.new(component_collection: @collection)
    @media_component = MediaComponent.new(component_collection: @collection)
    @audio_component = AudioComponent.new(component_collection: @collection)
    @image_component = ImageComponent.new(component_collection: @collection)
    @video_component = VideoComponent.new(component_collection: @collection)
  end

  describe 'General' do

    it 'should create a component' do
      expect(@component).to be_valid
      @component.save!
      expect(Component.all.length).to eq(1)
      expect(@collection.reload.components.length).to eq(1)
    end

    it 'should create a component with default values' do
      @component.save!
      expect(@component.reload.index).to eq(0)
    end

    it 'should serialize free form data as part of metadata attr' do
      @component.metadata = { baz: 'qux', foo: 'bar' }
      @component.save!
      expect(@component.reload.metadata).to eql({ baz: 'qux', foo: 'bar' })

      @component.metadata = { 'baz': 'qux', 'foo': 'bar' }
      @component.save!
      expect(@component.reload.metadata).to eql({ baz: 'qux', foo: 'bar' })

      @component.metadata = [1, 2, 3, 4, 5]
      @component.save!
      expect(@component.reload.metadata).to eql([1, 2, 3, 4, 5])
    end

    it 'should destroy a component' do
      @component.save!
      @component.destroy!
      expect(Component.all.length).to eq(0)
    end

  end

  describe 'Media Components' do
    it 'should remove any object from the media attribute that isnt a hash' do

      @media_component = MediaComponent.new(component_collection: @collection)
      File.open('test/helpers/file.mp3') do |f|
        @media_component.media = f
      end
      @media_component.save!
      expect(@media_component.reload.media_processing).to eq(true)
      expect(@media_component.media).to be_nil

      @media_component = MediaComponent.new(component_collection: @collection)
      @media_component.media = 'data:image/jpeg;base64;10101010100101010'
      @media_component.save!
      expect(@media_component.reload.media_processing).to eq(true)
      expect(@media_component.media).to be_nil

      @media_component = MediaComponent.new(component_collection: @collection)
      File.open('test/helpers/file.mp4') do |f|
        @media_component.media = f
      end
      @media_component.save!
      expect(@media_component.reload.media_processing).to eq(true)
      expect(@media_component.media).to be_nil

      @media_component = MediaComponent.new(component_collection: @collection)
      File.open('test/helpers/file.bin') do |f|
        @media_component.media = f
      end
      @media_component.save!
      expect(@media_component.reload.media_processing).to eq(true)
      expect(@media_component.media).to be_nil
    end

  end

  describe 'Audio Components' do

    it 'should remove any object from the media attribute that isnt a hash' do
      File.open('test/helpers/file.wav') do |f|
        @audio_component.media = f
      end
      @audio_component.save
      expect(@audio_component.reload.media_processing).to eq(true)
      expect(@audio_component.media).to be_nil
    end

  end

  describe 'Image Components' do

    it 'should remove any object from the media attribute that isnt a hash' do
      File.open('test/helpers/file.png') do |f|
        @image_component.media = f
      end
      @image_component.save
      expect(@image_component.reload.media_processing).to eq(true)
      expect(@image_component.media).to be_nil
    end
  end

  describe 'Video Components' do

    it 'should remove any object from the media attribute that isnt a hash' do
      File.open('test/helpers/file.mp4') do |f|
        @video_component.media = f
      end
      @video_component.save!
      expect(@video_component.reload.media_processing).to eq(true)
      expect(@video_component.media).to be_nil
    end

  end

end
