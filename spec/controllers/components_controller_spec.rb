require 'rails_helper'
require 'model_helper'
require "stubs/s3_stub"
include ModelHelper

RSpec.describe V1::ComponentsController do

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

  describe 'DELETE destroy' do

    it 'should delete a component' do
      @collection = ComponentCollection.new
      @component = Component.new(media: 'foo')
      @collection.components << @component
      @page.component_collections << @collection
      @page.save!

      process :destroy, method: :delete, params: {
        page_id: @page.id,
        collection_id: @collection.id,
        id: @component.id
      }

      expect(response.status).to eq(200)
      expect(ComponentCollection.all.length).to eq(1)
      expect(Component.all.length).to eq(0)

      @component1 = Component.new(media: 'foo')
      @component2 = Component.new(media: 'foo')
      @collection.components << @component1
      @collection.components << @component2
      @collection.save!
      expect(ComponentCollection.all.length).to eq(1)
      expect(Component.all.length).to eq(2)

      process :destroy, method: :delete, params: {
        page_id: @page.id,
        collection_id: @collection.id,
        id: @component2.id
      }

      expect(response.status).to eq(200)
      expect(ComponentCollection.all.length).to eq(1)
      expect(Component.all.length).to eq(1)
    end

    it 'should only delete a component if the associated page is owned by the current user' do
      allow(controller).to receive(:current_user).and_return(new_user)
      @collection = ComponentCollection.new
      @component = Component.new(media: 'foo')
      @collection.components << @component
      @page.component_collections << @collection
      @page.save!

      process :destroy, method: :delete, params: {
        page_id: @page.id,
        collection_id: @collection.id,
        id: @component.id
      }

      expect(response.status).to eq(403)
      expect(ComponentCollection.all.length).to eq(1)
      expect(Component.all.length).to eq(1)
    end

    it 'should only delete a component if the associated collection is owned by the current user' do
      allow(controller).to receive(:current_user).and_return(new_user)
      @collection = ComponentCollection.new
      @component = Component.new(media: 'foo')
      @collection.components << @component
      @collection.collectible = @current_user
      @collection.save!

      process :destroy, method: :delete, params: {
        collection_id: @collection.id,
        id: @component.id
      }

      expect(response.status).to eq(403)
      expect(ComponentCollection.all.length).to eq(1)
      expect(Component.all.length).to eq(1)
    end

  end

  describe 'GET index' do

    it 'should return a list of components associated with a collection if the page is published' do
      @collection = ComponentCollection.new
      @component = Component.new(media: 'foo')
      @collection.components << @component
      @component = Component.new(media: 'bar')
      @collection.components << @component
      @page.component_collections << @collection
      @page.published = true
      @page.save!

      process :index, method: :get, params: {
        page_id: @page.id,
        collection_id: @collection.id
      }
      parse_response

      expect(@res.length).to eq(2)
      expect(@res[0]['media']). to eq('foo')
      expect(@res[1]['media']). to eq('bar')
    end

    it 'should return a list of components associated with a collection if the page is published' do
      allow(controller).to receive(:current_user).and_return(new_user)
      @collection = ComponentCollection.new
      @component = Component.new(media: 'foo')
      @collection.components << @component
      @component = Component.new(media: 'bar')
      @collection.components << @component
      @page.component_collections << @collection
      @page.save!

      process :index, method: :get, params: {
        page_id: @page.id,
        collection_id: @collection.id
      }
      parse_response

      expect(response.status).to eq(403)
    end

    it 'should return a list of components associated with a collection if the user owns the page' do
      @collection = ComponentCollection.new
      @component = Component.new(media: 'foo')
      @collection.components << @component
      @component = Component.new(media: 'bar')
      @collection.components << @component
      @page.component_collections << @collection
      @page.save!

      process :index, method: :get, params: {
        page_id: @page.id,
        collection_id: @collection.id
      }
      parse_response

      expect(@res.length).to eq(2)
      expect(@res[0]['media']). to eq('foo')
      expect(@res[1]['media']). to eq('bar')
    end

    it 'should return a list of components associated with a collection if the user owns the page' do
      allow(controller).to receive(:current_user).and_return(new_user)
      @collection = ComponentCollection.new
      @component = Component.new(media: 'foo')
      @collection.components << @component
      @component = Component.new(media: 'bar')
      @collection.components << @component
      @page.component_collections << @collection
      @page.save!

      process :index, method: :get, params: {
        page_id: @page.id,
        collection_id: @collection.id
      }
      parse_response

      expect(response.status).to eq(403)
    end

    it 'should return a list of components associated with a collection if the user owns the collection' do
      @collection = ComponentCollection.new
      @component = Component.new(media: 'foo')
      @collection.components << @component
      @component = Component.new(media: 'bar')
      @collection.components << @component
      @collection.collectible = @current_user
      @collection.save!

      process :index, method: :get, params: {
        collection_id: @collection.id
      }
      parse_response

      expect(@res.length).to eq(2)
      expect(@res[0]['media']). to eq('foo')
      expect(@res[1]['media']). to eq('bar')
    end

    it 'should return a list of components associated with a collection if the user owns the collection' do
      allow(controller).to receive(:current_user).and_return(new_user)
      @collection = ComponentCollection.new
      @component = Component.new(media: 'foo')
      @collection.components << @component
      @component = Component.new(media: 'bar')
      @collection.components << @component
      @collection.collectible = @current_user
      @collection.save!

      process :index, method: :get, params: {
        collection_id: @collection.id
      }
      parse_response

      expect(response.status).to eq(403)
    end

  end

  describe 'GET show' do

    it 'should return a single component' do
      @collection = ComponentCollection.new
      @component = Component.new(media: 'foo')
      @collection.components << @component
      @page.component_collections << @collection
      @page.save!

      process :show, method: :get, params: {
        page_id: @page.id,
        collection_id: @collection.id,
        id: @component.id
      }
      parse_response

      expect(@res['id']).to_not be_nil
    end

    it 'should return a single component by a user who owns the collection (happy path)' do
      @collection = ComponentCollection.new
      @component = Component.new(media: 'foo')
      @collection.components << @component
      @collection.collectible = @current_user
      @collection.save!

      process :show, method: :get, params: {
        collection_id: @collection.id,
        id: @component.id
      }
      parse_response

      expect(@res['id']).to_not be_nil
    end

    it 'should return a single component by a user who owns the collection (sad path)' do
      @collection = ComponentCollection.new
      @component = Component.new(media: 'foo')
      @collection.components << @component
      @collection.collectible = @current_user
      @collection.save!

      allow(controller).to receive(:current_user).and_return(new_user)

      process :show, method: :get, params: {
        collection_id: @collection.id,
        id: @component.id
      }
      parse_response

      expect(response.status).to eq(403)
    end


    it 'should return a single component by an unauthored user if the page is published' do
      allow(controller).to receive(:current_user).and_return(new_user)

      @collection = ComponentCollection.new
      @component = Component.new(media: 'foo')
      @collection.components << @component
      @page.component_collections << @collection
      @page.save!

      process :show, method: :get, params: {
        page_id: @page.id,
        collection_id: @collection.id,
        id: @component.id
      }
      parse_response

      expect(response.status).to eq(403)
    end

    it 'should return a single component by an unauthored user if the page is published' do
      allow(controller).to receive(:current_user).and_return(new_user)

      @collection = ComponentCollection.new
      @component = Component.new(media: 'foo')
      @collection.components << @component
      @page.component_collections << @collection
      @page.published = true
      @page.save!

      process :show, method: :get, params: {
        page_id: @page.reload.id,
        collection_id: @collection.id,
        id: @component.id
      }
      parse_response

      expect(@res['id']).to_not be_nil
    end

    it 'should return a 404 if the component is not found' do
      @collection = ComponentCollection.new
      @component = Component.new(media: 'foo')
      @collection.components << @component
      @page.component_collections << @collection
      @page.save!

      process :show, method: :get, params: {
        page_id: @page.id,
        collection_id: @collection.id,
        id: 123
      }
      parse_response

      expect(response.status).to eq(404)
    end
  end

  describe 'Resumable uploads' do

    include_context 's3 stub'

    before :each do
      @collection = ComponentCollection.new
      @image = new_image_component
      @collection.components << @image
      @page.component_collections << @collection
      @page.save!
      # the image component has been created and media_processing flag has been set to true
      expect(@image.reload.media_processing).to eq(true)

      @file = Rack::Test::UploadedFile.new('test/helpers/big.jpeg', 'image/jpeg')

      stub_all_s3_calls
    end

    after :each do
      @file.close
    end

    it 'should upload a small file in one request' do
      file = Rack::Test::UploadedFile.new('test/helpers/file.png', 'image/png')
      process :upload, method: :post, params: {
        component_id: @image.id,
        file: file,
        filename: 'file.png',
        _total_size: file.size,
        _current_part_size: 5*1024*1024+1,
        _part_number: 1
      }
      parse_response
      expect(@res['media']['upload']['upload_id']).to be_nil
      expect(@res['media']['upload']['uploaded_size']).to eq(file.size)
      expect(@res['media']['upload']['last_uploaded_part_number']).to be_nil
      expect(@res['media']['upload']['upload_complete']).to eq(true)
      expect(@res['media']['original']['url']).to_not be_nil
    end

    it 'should upload a file in one part if no total size parameter is given' do
      file = Rack::Test::UploadedFile.new('test/helpers/big.jpeg', 'image/jpeg')
      # will upload whatever data is given as one part if no totalSize, currentChunk, or chunkNumber params are given
      process :upload, method: :post, params: {
        component_id: @image.id,
        file: file,
        filename: 'file.png'
      }
      parse_response
      expect(@res['media']['upload']['upload_id']).to_not be_nil
      expect(@res['media']['upload']['uploaded_size']).to eq(file.size)
      expect(@res['media']['upload']['last_uploaded_part_number']).to eq(1)
      expect(@res['media']['upload']['upload_complete']).to eq(true)
      expect(@res['media']['original']['url']).to_not be_nil
    end

    it 'should upload a file in one part if no total size parameter is given and chunk number is out of order' do
      file = Rack::Test::UploadedFile.new('test/helpers/big.jpeg', 'image/jpeg')
      # will upload whatever data is given as one part if no totalSize, currentChunk, or chunkNumber params are given
      process :upload, method: :post, params: {
        component_id: @image.id,
        file: file,
        filename: 'file.png',
        _part_number: 13,
      }
      parse_response
      expect(@res['media']['upload']['upload_id']).to_not be_nil
      expect(@res['media']['upload']['uploaded_size']).to eq(file.size)
      expect(@res['media']['upload']['last_uploaded_part_number']).to eq(14)
      expect(@res['media']['upload']['upload_complete']).to eq(true)
      expect(@res['media']['original']['url']).to_not be_nil
    end

    it 'should reject a request without a filename' do
      first_chunk = Tempfile.new
      first_chunk.binmode
      first_chunk.write @file.read(5*1024*1024+1)

      process :upload, method: :post, params: {
        component_id: @image.id,
        file: Rack::Test::UploadedFile.new(first_chunk, 'application/octet-stream'),
        _total_size: @file.size,
        _current_part_size: 5*1024*1024+1,
        _part_number: 1
      }
      parse_response
      expect(response.status).to eq(400)
      expect(@image.reload.media).to eq(nil)
    end

    it 'should reject a request without a file' do
      first_chunk = Tempfile.new
      first_chunk.binmode
      first_chunk.write @file.read(5*1024*1024+1)

      process :upload, method: :post, params: {
        component_id: @image.id,
        filename: 'file.png',
        _total_size: @file.size,
        _current_part_size: 5*1024*1024+1,
        _part_number: 1
      }
      parse_response
      expect(response.status).to eq(400)
      expect(@image.reload.media).to eq(nil)
    end

    it 'should reject a request for a component that is not a MediaComponent' do
      component = Component.new
      component.save
      first_chunk = Tempfile.new
      first_chunk.binmode
      first_chunk.write @file.read(5*1024*1024+1)

      process :upload, method: :post, params: {
        component_id: component.id,
        file: Rack::Test::UploadedFile.new(first_chunk, 'application/octet-stream'),
        filename: 'file.png',
        _total_size: @file.size,
        _current_part_size: 5*1024*1024+1,
        _part_number: 1
      }
      parse_response
      expect(response.status).to eq(400)
      expect(component.reload.media).to eq(nil)
    end

    it 'should upload a file in chunks' do
      # we can upload a file in parts by specifying _totalSize _chunkNumber
      first_chunk = Tempfile.new
      second_chunk = Tempfile.new
      first_chunk.binmode
      second_chunk.binmode
      first_chunk.write @file.read(5*1024*1024+1)
      second_chunk.write @file.read
      first_chunk.rewind
      second_chunk.rewind
      # for this example we will split 'file.png' into two requests
      process :upload, method: :post, params: {
        component_id: @image.id,
        file: Rack::Test::UploadedFile.new(first_chunk, 'application/octet-stream'),
        filename: 'file.png',
        _total_size: @file.size,
        _current_part_size: 5*1024*1024+1,
        _part_number: 1
      }
      parse_response
      expect(@res['media']['upload']['upload_id']).to_not be_nil
      expect(@res['media']['upload']['uploaded_size']).to eq(5242881)
      expect(@res['media']['upload']['last_uploaded_part_number']).to_not be_nil
      expect(@res['media']['upload']['last_uploaded_etag']).to_not be_nil
      expect(@res['media']['upload']['upload_complete']).to eq(false)
      expect(@res['media']['upload']['uploaded_parts']).to eq([2])

      process :upload, method: :post, params: {
        component_id: @image.id,
        file: Rack::Test::UploadedFile.new(second_chunk, 'application/octet-stream'),
        filename: 'file.png',
        _total_size: @file.size,
        _part_number: 2
      }
      parse_response
      expect(@res['media']['upload']['upload_id']).to_not be_nil
      expect(@res['media']['upload']['uploaded_size']).to eq(@file.size)
      expect(@res['media']['upload']['last_uploaded_part_number']).to_not be_nil
      expect(@res['media']['upload']['last_uploaded_etag']).to_not be_nil
      expect(@res['media']['upload']['upload_complete']).to eq(true)
      expect(@res['media']['upload']['uploaded_parts']).to eq([2, 3])
      expect(@res['media']['original']['url']).to_not be_nil
    end

    it 'should allow the same chunk to be uploaded again' do
      first_chunk = Tempfile.new
      second_chunk = Tempfile.new
      first_chunk.binmode
      second_chunk.binmode
      first_chunk.write @file.read(5*1024*1024+1)
      second_chunk.write @file.read
      first_chunk.rewind
      second_chunk.rewind
      # for this example we will split 'file.png' into two requests
      process :upload, method: :post, params: {
        component_id: @image.id,
        file: Rack::Test::UploadedFile.new(first_chunk, 'application/octet-stream'),
        filename: 'file.png',
        _total_size: @file.size,
        _part_number: 1
      }
      parse_response
      expect(@res['media']['upload']['upload_id']).to_not be_nil
      expect(@res['media']['upload']['uploaded_size']).to eq(5242881)
      expect(@res['media']['upload']['uploaded_parts']).to eq([2])

      # upload the same chunk again
      process :upload, method: :post, params: {
        component_id: @image.id,
        file: Rack::Test::UploadedFile.new(first_chunk, 'application/octet-stream'),
        filename: 'file.png',
        _total_size: @file.size,
        _current_part_size: 5*1024*1024+1,
        _part_number: 1
      }
      parse_response
      expect(@res['media']['upload']['upload_id']).to_not be_nil
      # uploaded size did not change
      expect(@res['media']['upload']['uploaded_size']).to eq(5242881)
      expect(@res['media']['upload']['uploaded_parts']).to eq([2])
    end

    it 'should reject a request for an upload that has been started but later :totalSize parameter has been omitted' do
      first_chunk = Tempfile.new
      second_chunk = Tempfile.new
      first_chunk.binmode
      second_chunk.binmode
      first_chunk.write @file.read(5*1024*1024+1)
      second_chunk.write @file.read
      first_chunk.rewind
      second_chunk.rewind
      # for this example we will split 'file.png' into two requests
      process :upload, method: :post, params: {
        component_id: @image.id,
        file: Rack::Test::UploadedFile.new(first_chunk, 'application/octet-stream'),
        filename: 'file.png',
        _total_size: @file.size,
        _part_number: 1
      }
      parse_response
      expect(@res['media']['upload']['upload_id']).to_not be_nil
      expect(@res['media']['upload']['uploaded_size']).to eq(5242881)
      expect(@res['media']['upload']['uploaded_parts']).to eq([2])

      # upload a different chunk but omit totalSize
      process :upload, method: :post, params: {
        component_id: @image.id,
        file: Rack::Test::UploadedFile.new(second_chunk, 'application/octet-stream'),
        filename: 'file.png',
        # missing :_totalSize
        _part_number: 2
      }
      parse_response
      expect(@res['errors']).to_not be_nil
    end

    it 'should add 1 to part numbers' do
      # we can upload a file in parts by specifying _totalSize _chunkNumber
      first_chunk = Tempfile.new
      second_chunk = Tempfile.new
      first_chunk.binmode
      second_chunk.binmode
      first_chunk.write @file.read(5*1024*1024+1)
      second_chunk.write @file.read
      first_chunk.rewind
      second_chunk.rewind
      # for this example we will split 'file.png' into two requests
      process :upload, method: :post, params: {
        component_id: @image.id,
        file: Rack::Test::UploadedFile.new(first_chunk, 'application/octet-stream'),
        filename: 'file.png',
        _total_size: @file.size,
        _current_part_size: 5*1024*1024+1,
        _part_number: 0
      }
      parse_response
      expect(@res['media']['upload']['last_uploaded_part_number']).to eq(1)
      expect(@res['media']['upload']['uploaded_parts']).to eq([1])

      process :upload, method: :post, params: {
        component_id: @image.id,
        file: Rack::Test::UploadedFile.new(second_chunk, 'application/octet-stream'),
        filename: 'file.png',
        _total_size: @file.size,
        _current_part_size: @file.size - (5*1024*1024+1),
        # it is the responsibility of the client now to take the returned :chunkNumber and increment correctly
        _part_number: @res['media']['upload']['last_uploaded_part_number'] + 1
      }
      parse_response
      expect(@res['media']['upload']['last_uploaded_part_number']).to eq(3)
      expect(@res['media']['upload']['uploaded_parts']).to eq([1, 3])
    end
  end

  describe 'POST create' do

    describe 'General Components' do
      it 'should add a new component to an existing collection' do
        @collection = ComponentCollection.new
        @component = Component.new(media: 'foo')
        @collection.components << @component
        @page.component_collections << @collection
        @page.save!

        process :create, method: :post, params: {
          page_id: @page.id,
          collection_id: @collection.id,
          media: 'bar',
          type: 'Component',
          metadata: {
              foo: 'bar',
              baz: 'qux'
          }
        }
        parse_response

        expect(@res['id']).to_not be_nil
        expect(@res['component_collection_id']).to_not be_nil
        expect(@res['index']).to eq(0)
        expect(@res['media']).to eq('bar')
        expect(@res['metadata']['foo']).to eq('bar')
        expect(@res['metadata']['baz']).to eq('qux')
        expect(@res['type']).to eq('Component')
        expect(Component.all.length).to eq(2)
      end

      it 'should add an index property to a component of any type' do
        @collection = ComponentCollection.new
        @page.component_collections << @collection
        @page.save!

        process :create, method: :post, params: {
          page_id: @page.id,
          collection_id: @collection.id,
          media: 'bar',
          type: 'ImageComponent',
          index: 47,
          metadata: {
              foo: 'bar',
              baz: 'qux'
          }
        }
        parse_response

        expect(@res['id']).to_not be_nil
        expect(@res['component_collection_id']).to_not be_nil
        expect(@res['index']).to eq(47)
        expect(@res['metadata']['foo']).to eq('bar')
        expect(@res['metadata']['baz']).to eq('qux')
        expect(@res['type']).to eq('ImageComponent')
        expect(Component.all.length).to eq(1)
      end

      it 'should add a new component only by the user who owns the page' do
        other_user = new_user
        other_user.save!
        allow(controller).to receive(:current_user).and_return(other_user)

        @collection = ComponentCollection.new
        @component = Component.new(media: 'foo')
        @collection.components << @component
        @page.component_collections << @collection
        @page.save!

        process :create, method: :post, params: {
          page_id: @page.id,
          collection_id: @collection.id,
          media: 'bar',
          type: 'Component',
          metadata: {
              foo: 'bar',
              baz: 'qux'
          }
        }

        expect(response.status).to eq(403)
        expect(Component.all.length).to eq(1)
      end

    end

    describe 'Audio Components' do

      it 'should add an audio component to an existing component collection' do
        @collection = ComponentCollection.new
        @audio = new_audio_component
        @collection.components << @audio
        @page.component_collections << @collection
        @page.save!

        process :create, method: :post, params: {
          page_id: @page.id,
          collection_id: @collection.id,
          media: Rack::Test::UploadedFile.new('test/helpers/file.mp3', 'audio/mp3'),
          type: 'AudioComponent',
          metadata: {
              duration: 5212,
              currentTime: 127,
              title: 'Hey Jude'
          }
        }
        parse_response

        expect(@res['id']).to_not be_nil
        expect(@res['type']).to eq('AudioComponent')
        expect(@res['metadata']['title']).to eq('Hey Jude')
      end

    end

    describe 'Image Components' do

      include_context 's3 stub'

      before :each do
        stub_all_s3_calls
      end

      it 'should add an image component to an existing component collection' do
        @collection = ComponentCollection.new
        @image = new_image_component
        @collection.components << @image
        @page.component_collections << @collection
        @page.save!

        process :create, method: :post, params: {
          page_id: @page.id,
          collection_id: @collection.id,
          media: Rack::Test::UploadedFile.new('test/helpers/file.png', 'image/png'),
          type: 'ImageComponent',
          metadata: {
              features: 5123,
              eigenvalues: [1, 2, 3]
          }
        }
        parse_response

        expect(@res['id']).to_not be_nil
        expect(@res['media']).to be_nil
        expect(@res['media_processing']).to eq(true)
        expect(@res['metadata']['eigenvalues']).to eq(['1', '2', '3'])

        component_id = @res['id']
        process :upload, method: :post, params: {
          component_id: component_id,
          filename: 'file.png',
          file: Rack::Test::UploadedFile.new('test/helpers/file.png', 'image/png')
        }

        parse_response

        expect(@res['id']).to_not be_nil
        expect(@res['media']).to_not be_nil
        expect(@res['media_processing']).to eq(true)
        expect(@res['media']['upload']['upload_complete']).to eq(true)
      end

    end

    describe 'Video Components' do

      it 'should add a video component to an existing component collection' do
        @collection = ComponentCollection.new
        @video = new_video_component
        @collection.components << @video
        @page.component_collections << @collection
        @page.save!

        process :create, method: :post, params: {
          page_id: @page.id,
          collection_id: @collection.id,
          media: Rack::Test::UploadedFile.new('test/helpers/file.mp4', 'video/mp4'),
          type: 'VideoComponent',
          metadata: {
              currentTime: 5123,
              ads: [1, 2, 3]
          }
        }
        parse_response

        expect(@res['id']).to_not be_nil
        expect(@res['media']).to be_nil
        expect(@res['media_processing']).to eq(true)
        expect(@res['metadata']['ads']).to eq(['1', '2', '3'])
      end

    end

    describe 'Media Components' do

      it 'should add a media component to an existing component collection' do
        @collection = ComponentCollection.new
        @media = new_media_component
        @collection.components << @media
        @page.component_collections << @collection
        @page.save!

        process :create, method: :post, params: {
          page_id: @page.id,
          collection_id: @collection.id,
          media: Rack::Test::UploadedFile.new('test/helpers/file.bin', 'application/html'),
          type: 'MediaComponent'
        }
        parse_response

        expect(@res['id']).to_not be_nil
        expect(@res['media']).to be_nil
        expect(@res['media_processing']).to eq(true)
        expect(Component.all.length).to eq(2)
      end

    end

  end

  describe 'PUT update' do

    it 'should update a component' do
      @collection = ComponentCollection.new
      @component = new_audio_component
      @collection.components << @component
      @page.component_collections << @collection
      @page.save!

      expect(@component.index).to eq(0)
      expect(@component.metadata).to be_nil

      process :update, method: :put, params: {
        page_id: @page.id,
        collection_id: @collection.id,
        id: @component.id,
        index: 123,
        metadata: {
            foo: 'bar'
        }
      }

      expect(@component.reload.index).to eq(123)
      expect(@component.reload.metadata['foo']).to eq('bar')
    end

    it 'should only update a component if the user owns the associated page' do
      @collection = ComponentCollection.new
      @component = new_audio_component
      @collection.components << @component
      @page.component_collections << @collection
      @page.user = new_user
      @page.save!

      expect(@component.index).to eq(0)
      expect(@component.metadata).to be_nil

      process :update, method: :put, params: {
        page_id: @page.id,
        collection_id: @collection.id,
        id: @component.id,
        index: 123,
        metadata: {
            foo: 'bar'
        }
      }

      expect(response.status).to eq(403)
    end

    it 'should only update a component if the user owns the associated collection' do
      @collection = ComponentCollection.new
      @component = new_audio_component
      @collection.components << @component
      @collection.collectible = @current_user
      @collection.save!

      expect(@component.index).to eq(0)
      expect(@component.metadata).to be_nil

      process :update, method: :put, params: {
        collection_id: @collection.id,
        id: @component.id,
        index: 123,
        metadata: {
            foo: 'bar'
        }
      }

      expect(@component.reload.index).to eq(123)
      expect(@component.reload.metadata['foo']).to eq('bar')
    end

    it 'should only update index and metadata attributes of a component' do
      @collection = ComponentCollection.new
      @component = new_audio_component
      @component.media = { foo: 'bar' }
      @collection.components << @component
      @collection.collectible = @current_user
      @collection.save!

      expect(@component.index).to eq(0)
      expect(@component.metadata).to be_nil
      expect(@component.media[:foo]).to_not be_nil
      old_media = @component.media

      process :update, method: :put, params: {
        collection_id: @collection.id,
        id: @component.id,
        index: 123,
        metadata: {
            foo: 'bar'
        },
        media: Rack::Test::UploadedFile.new('test/helpers/file.m4a', 'audio/mpeg')
      }
      parse_response

      new_media = @component.reload.media
      expect(new_media).to_not equal(old_media)
      expect(@res['metadata']['foo']).to eq('bar')
    end

    it 'should update the text of a text component' do
      @collection = ComponentCollection.new
      @component = Component.new(media: 'foo')
      @collection.components << @component
      @collection.collectible = @current_user
      @collection.save!

      expect(@component.media).to eq('foo')

      process :update, method: :put, params: {
        collection_id: @collection.id,
        id: @component.id,
        index: 2,
        metadata: {
            size: 'full'
        },
        media: 'bar'
      }
      parse_response

      expect(@res['media']).to eq('bar')
      expect(@res['index']).to eq(2)
      expect(@res['metadata']['size']).to eq('full')
      expect(@component.reload.media).to eq('bar')
    end

    it 'should only update parameters that are defined in request' do
      @collection = ComponentCollection.new
      @component = new_audio_component
      @component.index = 123
      @component.metadata = { foo: 'bar' }
      @collection.components << @component
      @collection.collectible = @current_user
      @collection.save!

      expect(@component.index).to eq(123)
      expect(@component.reload.metadata[:foo]).to eq('bar')

      process :update, method: :put, params: {
        collection_id: @collection.id,
        id: @component.id,
        index: 1234
      }

      expect(@component.reload.index).to eq(1234)
      expect(@component.reload.metadata[:foo]).to eq('bar')
    end

    it 'should set default values when nil values are sent' do
      @collection = ComponentCollection.new
      @component = new_audio_component
      @component.index = 123
      @collection.components << @component
      @collection.collectible = @current_user
      @collection.save!

      expect(@component.index).to eq(123)
      expect(@component.metadata).to be_nil

      process :update, method: :put, params: {
        collection_id: @collection.id,
        id: @component.id,
        index: nil,
        metadata: {
            foo: 'bar'
        }
      }
      parse_response

      expect(@res['index']).to eq(0)
      expect(@component.reload.index).to eq(0)
      expect(@component.reload.metadata['foo']).to eq('bar')
    end

  end

  describe 'Billing' do

    it 'should only allow create requests for users for the first 30 days of creating their account' do
      @current_user.created_at = 30.days.ago
      @current_user.save
      allow_any_instance_of(BillingHelper).to receive(:account_in_good_standing?).and_return(false)

      @collection = ComponentCollection.new
      @component = Component.new(media: 'foo')
      @collection.components << @component
      @page.component_collections << @collection
      @page.save!

      process :create, method: :post, params: {
        page_id: @page.id,
        collection_id: @collection.id,
        media: 'bar',
        type: 'Component',
        metadata: {
          foo: 'bar',
          baz: 'qux'
        }
      }

      json = JSON.parse(response.body)
      expect(json['errors']).to_not be_nil
      expect(response.status).to eq(403)
    end

    it 'should only allow update requests for users for the first 30 days of creating their account' do
      @current_user.created_at = 30.days.ago
      @current_user.save
      allow_any_instance_of(BillingHelper).to receive(:account_in_good_standing?).and_return(false)

      @collection = ComponentCollection.new
      @component = new_audio_component
      @collection.components << @component
      @page.component_collections << @collection
      @page.save!

      process :update, method: :put, params: {
        page_id: @page.id,
        collection_id: @collection.id,
        id: @component.id,
        index: 123,
        metadata: {
          foo: 'bar'
        }
      }

      json = JSON.parse(response.body)
      expect(json['errors']).to_not be_nil
      expect(response.status).to eq(403)
    end
  end

end
