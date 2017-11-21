require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe V1::SingleUseComponentCollectionsController do

  let(:user) {double :acceptable? => true}
  let(:token) {double :acceptable? => true}
  let(:tl_response) {double(:tl_response)}

  before :each do
    (@current_user = new_user) and @current_user.save!
    allow(controller).to receive(:set_current_user).and_return(nil)
    allow(controller).to receive(:authenticate_user!).and_return(user)
    allow(controller).to receive(:doorkeeper_token).and_return(token)
    allow(controller).to receive(:current_user).and_return(@current_user)


  end

  describe 'POST create' do

    it 'should create a single use component collection' do
      process :create, method: :post, params: {}
      parse_response

      expect(@res['id']).to_not be_nil
      expect(@res['components']).to eq([])
      expect(@res['collectible_id']).to eq(@current_user.id)
      expect(@res['collectible_type']).to eq('User')
      expect(ComponentCollection.all.length).to eq(1)
    end

    it 'should create a single use component collection -- Track' do
      process :create, method: :post, params: {
        type: 'ComponentCollection',
        components: [
          { index: 0, type: 'AudioComponent' }
        ]
      }
      parse_response

      expect(@res['id']).to_not be_nil
      expect(@res['type']).to eql('ComponentCollection')
      expect(@res['components'].length).to eq(1)
      expect(@res['components'][0]['media']).to be_nil
      expect(@res['components'][0]['media_processing']).to eq(true)
      expect(ComponentCollection.all.first.components.length).to eq(1)
      expect(@res['collectible_id']).to eq(@current_user.id)
      expect(@res['collectible_type']).to eq('User')
    end

    it 'should create a single use component collection -- ComponentCollection' do
      process :create, method: :post, params: {
        type: 'ComponentCollection',
        components: [
          { media: Rack::Test::UploadedFile.new('test/helpers/file.png', 'image/png'), type: 'ImageComponent' }
        ]
      }
      parse_response

      expect(@res['id']).to_not be_nil
      expect(@res['type']).to eql('ComponentCollection')
      expect(@res['components'].length).to eq(1)
      expect(@res['components'][0]['media']).to be_nil
      expect(@res['components'][0]['media_processing']).to eq(true)
      expect(ComponentCollection.all.first.components.length).to eq(1)
      expect(@res['collectible_id']).to eq(@current_user.id)
      expect(@res['collectible_type']).to eq('User')
    end

    it 'should create a single use component collection -- ComponentCollection' do
      process :create, method: :post, params: {
        type: 'ComponentCollection',
        components: [
          { index: 1, type: 'VideoComponent' }
        ]
      }
      parse_response

      expect(@res['id']).to_not be_nil
      expect(@res['type']).to eql('ComponentCollection')
      expect(@res['components'].length).to eq(1)
      expect(@res['components'][0]['media']).to be_nil
      expect(@res['components'][0]['media_processing']).to eq(true)
      expect(ComponentCollection.all.first.components.length).to eq(1)
      expect(@res['collectible_id']).to eq(@current_user.id)
      expect(@res['collectible_type']).to eq('User')
    end

    it 'should create a single use component collection -- Text' do
      process :create, method: :post, params: {
        type: 'ComponentCollection',
        components: [
          { media: 'foo' }
        ]
      }
      parse_response

      expect(@res['id']).to_not be_nil
      expect(@res['type']).to eql('ComponentCollection')
      expect(@res['components'].length).to eq(1)
      expect(@res['components'][0]['media']).to eq('foo')
      expect(ComponentCollection.all.first.components.length).to eq(1)
      expect(@res['collectible_id']).to eq(@current_user.id)
      expect(@res['collectible_type']).to eq('User')
    end

    it 'should create a single use component collection -- ComponentCollection' do
      process :create, method: :post, params: {
        type: 'ComponentCollection'
      }
      parse_response

      expect(@res['id']).to_not be_nil
      expect(@res['type']).to eql('ComponentCollection')
      expect(@res['collectible_id']).to eq(@current_user.id)
      expect(@res['collectible_type']).to eq('User')
    end

    it 'should create a single use component collection -- ComponentCollection' do
      process :create, method: :post, params: {
        type: 'ComponentCollection',
        components: [
          { index: 0, type: 'AudioComponent' },
          { index: 1, type: 'AudioComponent' },
          { index: 2, type: 'AudioComponent' },
          { index: 3, type: 'AudioComponent' }
        ]
      }
      parse_response

      expect(@res['id']).to_not be_nil
      expect(@res['type']).to eql('ComponentCollection')
      expect(@res['components'].length).to eq(4)
      expect(@res['components'][1]['media']).to be_nil
      expect(@res['components'][2]['index']).to eq(2)
      expect(@res['components'][0]['media_processing']).to eq(true)
      expect(ComponentCollection.all.first.components.length).to eq(4)
      expect(@res['collectible_id']).to eq(@current_user.id)
      expect(@res['collectible_type']).to eq('User')
    end

    it 'should create a single use component collection -- ComponentCollection' do
      process :create, method: :post, params: {
        type: 'ComponentCollection',
        components: [
          { index: 0, type: 'ImageComponent' },
          { index: 4, type: 'ImageComponent' },
          { index: 3, type: 'ImageComponent' },
          { media: Rack::Test::UploadedFile.new('test/helpers/file.png', 'image/png'), index: 8, type: 'ImageComponent' }
        ]
      }
      parse_response

      expect(@res['id']).to_not be_nil
      expect(@res['type']).to eql('ComponentCollection')
      expect(@res['components'].length).to eq(4)
      expect(@res['components'][0]['media']).to be_nil
      expect(@res['components'][0]['media_processing']).to eq(true)
      expect(@res['components'][1]['index']).to eq(4)
      expect(ComponentCollection.all.first.components.length).to eq(4)
      expect(@res['collectible_id']).to eq(@current_user.id)
      expect(@res['collectible_type']).to eq('User')
    end

    it 'should create a single use component collection -- ComponentCollection' do
      process :create, method: :post, params: {
        type: 'ComponentCollection',
        components: [
          { media: Rack::Test::UploadedFile.new('test/helpers/file.mp4', 'video/mp4'), type: 'VideoComponent' },
          { media: Rack::Test::UploadedFile.new('test/helpers/file.mp4', 'video/mp4'), type: 'VideoComponent' },
          { media: Rack::Test::UploadedFile.new('test/helpers/file.mp4', 'video/mp4'), type: 'VideoComponent' },
          { media: Rack::Test::UploadedFile.new('test/helpers/file.mp4', 'video/mp4'), type: 'VideoComponent' }
        ]
      }
      parse_response

      expect(@res['id']).to_not be_nil
      expect(@res['type']).to eql('ComponentCollection')
      expect(@res['components'].length).to eq(4)
      expect(@res['components'][0]['media']).to be_nil
      expect(@res['components'][0]['media_processing']).to eq(true)
      expect(ComponentCollection.all.first.components.length).to eq(4)
      expect(@res['collectible_id']).to eq(@current_user.id)
      expect(@res['collectible_type']).to eq('User')
    end

    it 'should not create a single use component collection without a user signed in' do
      allow(controller).to receive(:doorkeeper_token).and_return(nil)
      process :create, method: :post, params: {}

      expect(response.status).to eq(401)
      expect(ComponentCollection.all.length).to eq(0)
    end

  end

  describe 'GET show' do

    it 'should get a single use component collection' do
      @collection = ComponentCollection.new
      @collection.components << new_image_component
      @collection.components << new_audio_component
      @collection.collectible = @current_user
      @collection.save!

      process :show, method: :get, params: {
        id: @collection.id
      }
      parse_response

      expect(@res['id']).to_not be_nil
      expect(@res['components'].length).to eq(2)
      expect(@res['components'][0]['media']).to be_nil
      expect(@res['components'][0]['media_processing']).to eq(true)
    end

    it 'should not get a single use component collection if there is no user signed in' do
      allow(controller).to receive(:doorkeeper_token).and_return(nil)

      @collection = ComponentCollection.new
      @collection.components << new_image_component
      @collection.components << new_audio_component
      @collection.collectible = @current_user
      @collection.save!

      process :show, method: :get, params: {
        id: @collection.id
      }

      expect(response.status).to eq(401)
    end

    it 'should provide public permissions to single use component collection' do
      allow(controller).to receive(:current_user).and_return(new_user)

      @collection = ComponentCollection.new
      @collection.components << new_image_component
      @collection.components << new_audio_component
      @collection.collectible = @current_user
      @collection.save!

      process :show, method: :get, params: {
        id: @collection.id
      }

      expect(response.status).to eq(200)

      # TODO revisit private component collections at a later date
      # expect(response.status).to eq(403)
    end

  end

  describe 'GET index' do

    it 'should list component collections created by the signed in user' do
      @collection = ComponentCollection.new
      @collection.components << new_image_component
      @collection.components << new_audio_component
      @collection.collectible = @current_user
      @collection.save!
      @collection = ComponentCollection.new
      @collection.components << new_image_component
      @collection.components << new_audio_component
      @collection.collectible = @current_user
      @collection.save!

      process :index_by_user, method: :get
      parse_response

      expect(@res.length).to eq(2)
      expect(@res[0]['components'][0]['media']).to be_nil
      expect(@res[0]['components'][0]['media_processing']).to eq(true)
    end

  end

  describe 'DELETE destroy' do

    it 'should delete a component collection' do
      @collection1 = ComponentCollection.new
      @collection1.components << new_image_component
      @collection1.components << new_audio_component
      @collection1.collectible = @current_user
      @collection1.save!

      @page = new_page
      @page.user = @current_user
      @collection2 = ComponentCollection.new
      @collection2.components << new_image_component
      @collection2.components << new_audio_component
      @collection2.collectible = @page
      @collection2.save!

      process :destroy, method: :delete, params: {
        id: @collection1.id
      }

      expect(response.status).to eq(200)
      expect(ComponentCollection.all.length).to eq(1)
      expect(Component.all.length).to eq(2)

      process :destroy, method: :delete, params: {
        id: @collection2.id
      }

      expect(response.status).to eq(200)
      expect(ComponentCollection.all.length).to eq(0)
      expect(Component.all.length).to eq(0)
    end

    it 'should delete a component collection unless the signed in user owns it directly or via a page' do
      @collection1 = ComponentCollection.new
      @collection1.components << new_image_component
      @collection1.components << new_audio_component
      @collection1.collectible = new_user
      @collection1.save!

      @page = new_page
      @page.user = new_user
      @collection2 = ComponentCollection.new
      @collection2.components << new_image_component
      @collection2.components << new_audio_component
      @collection2.collectible = @page
      @collection2.save!

      process :destroy, method: :delete, params: {
        id: @collection1.id
      }

      expect(response.status).to eq(403)
      expect(ComponentCollection.all.length).to eq(2)
      expect(Component.all.length).to eq(4)

      process :destroy, method: :delete, params: {
        id: @collection2.id
      }

      expect(response.status).to eq(403)
      expect(ComponentCollection.all.length).to eq(2)
      expect(Component.all.length).to eq(4)
    end

  end

  describe 'PUT update' do

    it 'should update attributes of a component collection' do
      @collection = ComponentCollection.new
      @collection.components << Component.new(media: 'foo')
      @collection.collectible = @current_user
      @collection.save!

      expect(@collection.index).to eq(0)
      expect(@collection.metadata).to be_nil

      process :update, method: :put, params: {
        id: @collection.id,
        index: 123,
        metadata: {
          foo: 'bar'
        }
      }
      parse_response

      expect(@res['index']).to eq(123)
      expect(@res['metadata']['foo']).to eq('bar')
    end

    it 'should only update attributes that are present in the request' do
      @collection = ComponentCollection.new
      @collection.components << Component.new(media: 'foo')
      @collection.metadata = {
        foo: 'bar'
      }
      @collection.collectible = @current_user
      @collection.save!

      process :update, method: :put, params: {
        id: @collection.id,
        index: 123
      }
      parse_response

      expect(@res['index']).to eq(123)
      expect(@res['metadata']['foo']).to eq('bar')
    end

    it 'should update attributes to nil if they are present in the request' do
      @collection = ComponentCollection.new
      @collection.components << Component.new(media: 'foo')
      @collection.metadata = {
        foo: 'bar'
      }
      @collection.collectible = @current_user
      @collection.save!

      process :update, method: :put, params: {
        id: @collection.id,
        index: 123,
        metadata: nil
      }
      parse_response

      expect(@res['index']).to eq(123)
      expect(@res['metadata']).to eq('')
    end

    it 'should update attributes to default values if nil is sent' do
      @collection = ComponentCollection.new
      @collection.components << Component.new(media: 'foo')
      @collection.index = 123
      @collection.collectible = @current_user
      @collection.save!

      process :update, method: :put, params: {
        id: @collection.id,
        index: nil
      }
      parse_response
      expect(@res['index']).to eq(0)
      expect(@res['metadata']).to be_nil
    end

    it 'should not allow for the type attribute to be changed' do
      @collection = ComponentCollection.new
      @collection.components << new_image_component
      @collection.components << new_image_component
      @collection.index = 123
      @collection.collectible = @current_user
      @collection.save!

      process :update, method: :put, params: {
        id: @collection.id,
        type: 'ComponentCollection'
      }
      parse_response
      expect(@res['index']).to eq(123)
    end

  end

end
