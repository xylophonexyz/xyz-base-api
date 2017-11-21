require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe V1::ComponentCollectionsController do

  let(:user) { double :acceptable? => true }
  let(:token) { double :acceptable? => true }
  let(:tl_response) { double(:tl_response) }

  before :each do
    (@current_user = new_user) and @current_user.save!
    (@page = new_page) and (@page.user = @current_user) and @page.save
    allow(controller).to receive(:set_current_user).and_return(nil)
    allow(controller).to receive(:authenticate_user!).and_return(user)
    allow(controller).to receive(:doorkeeper_token).and_return(token)
    allow(controller).to receive(:current_user).and_return(@current_user)


  end

  describe 'POST create' do
    #
    # components controller supports creating components as part of component collections.
    # creating single components is not supported, instead a BareCollection should be used.
    # additionally, several single instance types are available, such as Audio, ComponentCollection, Video, Text, and Spacer.
    # custom components can be created via the api and arbitrary data may be stored inside the :metadata attribute.
    #
    # component collections are also supported and may be created without any components in them. Custom
    # collections can be created and arbitrary data may be stored under the :metadata attribute.
    #

    describe 'Component Collections' do

      it 'should create a new component collection' do
        process :create, method: :post, params: { page_id: @page.id }
        parse_response

        expect(@res['id']).to_not be_nil
        expect(@res['components']).to eq([])
        expect(@res['collectible_id']).to_not be_nil
        expect(ComponentCollection.all.length).to eq(1)
      end

      it 'should not create a component collection by a user other than the pages owner' do
        allow(controller).to receive(:current_user).and_return(new_user)
        process :create, method: :post, params: { page_id: @page.id }
        parse_response
        expect(response.status).to eq(403)
      end

      it 'should accept index metadata on create' do
        process :create, method: :post, params: {
          page_id: @page.id,
          index: 123
        }
        parse_response

        expect(@res['id']).to_not be_nil
        expect(@res['index']).to eq(123)
        expect(ComponentCollection.all.first.index).to eq(123)
      end

      it 'should accept json metadata on create' do
        process :create, method: :post, params: {
          page_id: @page.id,
          metadata: {
              foo: 'bar',
              baz: 'qux'
          }
        }
        parse_response

        expect(@res['id']).to_not be_nil
        expect(@res['metadata']['foo']).to eq('bar')
        expect(@res['metadata']['baz']).to eq('qux')
        expect(ComponentCollection.all.first.metadata[:foo]).to eq('bar')
        expect(ComponentCollection.all.first.metadata[:baz]).to eq('qux')
      end

      it 'should accept type metadata on create' do
        process :create, method: :post, params: {
          page_id: @page.id,
          type: 'ComponentCollection'
        }
        parse_response

        expect(@res['id']).to_not be_nil
        expect(@res['type']).to eql('ComponentCollection')
        expect(ComponentCollection.all.first.type).to eq('ComponentCollection')

        process :create, method: :post, params: {
          page_id: @page.id,
          type: 'ComponentCollection'
        }
        parse_response

        expect(@res['id']).to_not be_nil
        expect(@res['type']).to eql('ComponentCollection')
        expect(ComponentCollection.all.length).to eq(2)
      end

      it 'should accept a list of components to create' do
        process :create, method: :post, params: {
          page_id: @page.id,
          index: 1,
          metadata: {
              foo: 'bar',
              baz: 'qux'
          },
          components: [
              { media: Rack::Test::UploadedFile.new('test/helpers/file.mp3', 'audio/mp3'), type: 'MediaComponent' },
              { media: Rack::Test::UploadedFile.new('test/helpers/file.bin', 'audio/mp3'), type: 'MediaComponent' },
              { media: Rack::Test::UploadedFile.new('test/helpers/file.mp3', 'audio/mp3'), type: 'AudioComponent' },
            { media: 'Hello', type: 'Component' },
              { media: Rack::Test::UploadedFile.new('test/helpers/file.png', 'image/png'), type: 'ImageComponent' },
              { media: 123 }
          ]
        }
        parse_response

        expect(@res['id']).to_not be_nil
        expect(@res['components'].length).to eq(6)
        expect(@res['components'][0]['media']).to be_nil
        expect(@res['components'][0]['media_processing']).to eq(true)
        expect(@res['components'][1]['media']).to be_nil
        expect(@res['components'][1]['media_processing']).to eq(true)
        expect(@res['components'][2]['media']).to be_nil
        expect(@res['components'][2]['media_processing']).to eq(true)
        expect(@res['components'][3]['media']).to eq('Hello')
        expect(@res['components'][3]['media_processing']).to be_nil
        expect(@res['components'][4]['media']).to be_nil
        expect(@res['components'][4]['media_processing']).to eq(true)
        expect(@res['components'][5]['media']).to eq(123.to_s)
        expect(@res['components'][5]['media_processing']).to be_nil
        expect(ComponentCollection.all.first.components.length).to eq(6)
      end

    end

  end

  describe 'DELETE destroy' do

    it 'should delete a component collection' do
      @collection = ComponentCollection.new
      @collection.components << Component.new(media: 'foo')
      @page.component_collections << @collection
      @page.save!

      process :destroy, method: :delete, params: {
        page_id: @page.id,
        id: @collection.id
      }

      expect(response.status).to eq(200)
      expect(ComponentCollection.all.length).to eq(0)
      expect(Component.all.length).to eq(0)
    end

    it 'should only delete a component collection if the associated page is owned by the current user' do
      allow(controller).to receive(:current_user).and_return(new_user)
      @collection = ComponentCollection.new
      @collection.components << Component.new(media: 'foo')
      @page.component_collections << @collection
      @page.save!

      process :destroy, method: :delete, params: {
        page_id: @page.id,
        id: @collection.id
      }

      expect(response.status).to eq(403)
      expect(ComponentCollection.all.length).to eq(1)
      expect(Component.all.length).to eq(1)
    end

  end

  describe 'GET index' do

    it 'should list all component collections associated with a page' do
      @collection = ComponentCollection.new
      @page.component_collections << @collection
      @page.save!

      process :index, method: :get, params: {
        page_id: @page.id
      }
      parse_response

      expect(@res.length).to eq(1)
    end

    it 'should list all collections associated with a published page if the requesting user doesnt own it' do
      @collection = ComponentCollection.new
      @page.component_collections << @collection
      @page.published = true
      @page.save!

      process :index, method: :get, params: {
        page_id: @page.id
      }
      parse_response

      expect(@res.length).to eq(1)
    end

    it 'should list all collections associated with a page if the requesting user owns it' do
      allow(controller).to receive(:current_user).and_return(new_user)
      @collection = ComponentCollection.new
      @page.component_collections << @collection
      @page.save!

      process :index, method: :get, params: {
        page_id: @page.id
      }
      parse_response

      expect(response.status).to eq(403)
    end

    it 'should list all component collections associated with a user' do
      @collection = ComponentCollection.new
      @collection.components << Component.new(media: 'foo')
      @page.component_collections << @collection
      @page.published = true
      @page.save!

      @page = new_page
      @page.user = new_user
      @collection = ComponentCollection.new
      @collection.components << Component.new(media: 'foo')
      @page.component_collections << @collection
      @page.published = true
      @page.save!

      process :index_by_user, method: :get, params: {
        user_id: @current_user.id
      }
      parse_response

      expect(@res.length).to eq(1)
      expect(@res[0]['components'].length).to eq(1)
      expect(@res[0]['components'][0]['media']).to eq('foo')
    end

    it 'should list all component collections associated with a user from published pages only' do
      @collection = ComponentCollection.new
      @collection.components << Component.new(media: 'foo')
      @page.component_collections << @collection
      @page.save!

      process :index_by_user, method: :get, params: {
        user_id: @current_user.id
      }
      parse_response

      expect(@res.length).to eq(0)
    end

    it 'should list associated components' do
      @collection = ComponentCollection.new
      @collection.components << Component.new(media: 'foo')
      @page.component_collections << @collection
      @page.save!

      process :index, method: :get, params: {
        page_id: @page.id
      }
      parse_response

      expect(@res.length).to eq(1)
      expect(@res[0]['components'].length).to eq(1)
      expect(@res[0]['components'][0]['media']).to eq('foo')
    end

    it 'should list all component collections for any user if the page is published' do
      allow(controller).to receive(:current_user).and_return(new_user)
      @collection = ComponentCollection.new
      @collection.components << Component.new(media: 'foo')
      @page.component_collections << @collection
      @page.published = true
      @page.save!

      process :index, method: :get, params: {
        page_id: @page.id
      }
      parse_response

      expect(@res.length).to eq(1)
      expect(@res[0]['components'].length).to eq(1)
      expect(@res[0]['components'][0]['media']).to eq('foo')
    end

  end

  describe 'GET show' do

    it 'should get a component collection and all associated components' do
      @collection = ComponentCollection.new
      @collection.components << Component.new(media: 'foo')
      @page.component_collections << @collection
      @page.save!

      process :show, method: :get, params: {
        page_id: @page.id,
        id: @collection.id
      }
      parse_response

      expect(@res['id']).to_not be_nil
      expect(@res['components'].length).to eq(1)
      expect(@res['components'][0]['media']).to eq('foo')
    end

    it 'should get a component collection regardless of user' do
      allow(controller).to receive(:current_user).and_return(new_user)
      @collection = ComponentCollection.new
      @collection.components << Component.new(media: 'foo')
      @page.component_collections << @collection
      @page.save!

      process :show, method: :get, params: {
        page_id: @page.id,
        id: @collection.id
      }
      parse_response

      expect(@res['id']).to_not be_nil
      expect(@res['components'].length).to eq(1)
      expect(@res['components'][0]['media']).to eq('foo')
    end

    it 'should return a 404 if a component collection is not found' do
      @collection = ComponentCollection.new
      @collection.components << Component.new(media: 'foo')
      @page.component_collections << @collection
      @page.save!

      process :show, method: :get, params: {
        page_id: @page.id,
        id: 123123
      }
      parse_response

      expect(response.status).to eq(404)
    end

  end

  describe 'PUT update' do

    it 'should update attributes of a component collection' do
      @collection = ComponentCollection.new
      @collection.components << Component.new(media: 'foo')
      @page.component_collections << @collection
      @page.save!

      expect(@collection.index).to eq(0)
      expect(@collection.metadata).to be_nil

      process :update, method: :put, params: {
        page_id: @page.id,
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
      @page.component_collections << @collection
      @page.save!

      process :update, method: :put, params: {
        page_id: @page.id,
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
      @page.component_collections << @collection
      @page.save!

      process :update, method: :put, params: {
        page_id: @page.id,
        id: @collection.id,
        index: 123,
        metadata: ''
      }
      parse_response

      expect(@res['index']).to eq(123)
      expect(@res['metadata']).to eq('')
    end

    it 'should update attributes to default values if nil is sent' do
      @collection = ComponentCollection.new
      @collection.components << Component.new(media: 'foo')
      @collection.index = 123
      @page.component_collections << @collection
      @page.save!
      process :update, method: :put, params: {
        page_id: @page.id,
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
      @page.component_collections << @collection
      @page.save!
      process :update, method: :put, params: {
        page_id: @page.id,
        id: @collection.id,
        type: 'ComponentCollection'
      }
      parse_response
      expect(@res['index']).to eq(123)
    end

    it 'should only allow updated by the user who owns the associated page' do
      @collection = ComponentCollection.new
      @collection.components << new_image_component
      @collection.components << new_image_component
      @collection.index = 123
      @page.component_collections << @collection
      @page.user = new_user
      @page.save!
      process :update, method: :put, params: {
        page_id: @page.id,
        id: @collection.id,
        index: 1234
      }

      expect(response.status).to eq(403)
      expect(@collection.reload.index).to eq(123)
    end

    it 'should "unlink" a collection from its parent association' do
      @collection = ComponentCollection.new
      @collection.components << Component.new(media: 'foo')
      @page.component_collections << @collection
      @page.save!

      expect(@collection.collectible).to eq(@page)

      # remove association and update :index and :metadata values in the same request
      process :update, method: :put, params: {
        page_id: @page.id,
        id: @collection.id,
        unlink: true,
        index: 123,
        metadata: {
            foo: 'bar'
        }
      }
      parse_response

      expect(@res['index']).to eq(123)
      expect(@res['collectible_id']).to eq(@current_user.id)
      expect(@res['collectible_type']).to eq('User')
      expect(@res['metadata']['foo']).to eq('bar')
      # when in "unlinked" state, the collection will associate to the current user
      expect(@collection.reload.collectible).to eq(@current_user)
    end

    it 'should "link" a collection to a parent' do
      @collection = ComponentCollection.new
      @collection.components << Component.new(media: 'foo')
      @collection.collectible = @current_user
      @collection.save!
      @page.save!

      # link collection to page
      process :update, method: :put, params: {
        id: @collection.id,
        collectible_id: @page.id,
        collectible_type: 'Page',
        index: 456,
        metadata: {
            foo: 'baz'
        }
      }
      parse_response

      expect(@res['index']).to eq(456)
      expect(@res['collectible_id']).to eq(@page.id)
      expect(@res['collectible_type']).to eq('Page')
      expect(@res['metadata']['foo']).to eq('baz')
      expect(@collection.reload.collectible).to eq(@page)
    end

  end

end
