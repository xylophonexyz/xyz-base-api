require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe V1::PagesController do

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

  describe 'GET index' do

    it 'should return a list of published pages' do
      @page.update(published: true)
      process :index, method: :get
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
    end

    it 'should return a list of all pages authored by the current user' do
      page = new_page
      page.user = @current_user
      page.save!
      @page.update(published: true)
      process :index_by_current_user, method: :get
      json = JSON.parse(response.body)
      expect(json.length).to eq(2)

      (unauthor = new_user) and unauthor.save!
      allow(controller).to receive(:current_user).and_return(unauthor)

      process :index_by_current_user, method: :get
      json = JSON.parse(response.body)
      expect(json.length).to eq(0)
    end

    it 'should return a list of published pages authored by the current user' do
      page = new_page
      page.user = @current_user
      page.save!
      @page.update(published: true)
      process :index_by_current_user, method: :get, params: { published: :published }
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)

      (unauthor = new_user) and unauthor.save!
      allow(controller).to receive(:current_user).and_return(unauthor)

      process :index_by_current_user, method: :get
      json = JSON.parse(response.body)
      expect(json.length).to eq(0)
    end

    it 'should return a list of drafts authored by the current user' do
      process :index_by_current_user, method: :get, params: { published: :drafts }
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)

      @page.update(published: true)

      process :index_by_current_user, method: :get, params: { published: :drafts }
      json = JSON.parse(response.body)
      expect(json.length).to eq(0)
    end

    it 'should return a list of published pages that are authored by users followed by the current user' do
      (author = new_user) and author.save!
      author.followers << @current_user
      author.save!
      @page.update(user: author, published: true)

      process :index_by_following, method: :get
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['id']).to eq(@page.id)
    end

    it 'should return a list of published pages authored by a particular user' do
      @page.update(published: true)

      process :index_by_user, method: :get, params: {
        user_id: @current_user.id
      }

      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['id']).to eq(@page.id)
    end

    it 'should return a list of featured pages' do
      @page.update(published: true)

      process :index_by_featured, method: :get, params: {
        user_id: @current_user.id
      }

      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['id']).to eq(@page.id)
    end

    it 'should return a page in the format defined by PageSerializer' do
      @page.update(published: true)

      process :index, method: :get
      json = JSON.parse(response.body)

      res = json.first
      expect(res['title']).to eq(@page.title)
      expect(res['id']).to eq(@page.id)
      expect(res['views']).to eq(@page.views.length)
      expect(res['description']).to eq(@page.description)
      expect(res['user']['username']).to eq(@page.user.username)
    end
  end

  describe 'POST create' do

    it 'should create a page' do
      process :create, method: :post

      json = JSON.parse(response.body)
      expect(json['id']).to_not be_nil
      expect(json['published']).to eq(false)
      expect(response.status).to eq(201)
      expect { Page.find(json['id']) }.to_not raise_error
    end

    it 'should create a page with title and description params' do
      process :create, method: :post, params: {
        title: 'foo',
        description: 'bar'
      }

      json = JSON.parse(response.body)
      expect(json['id']).to_not be_nil
      expect(json['title']).to eq('foo')
      expect(json['description']).to eq('bar')
      expect(response.status).to eq(201)
      expect { Page.find(json['id']) }.to_not raise_error
    end

    it 'should not process invalid params' do
      process :create, method: :post, params: { title: '', foo: 'bar', baz: 'qux' }
      json = JSON.parse(response.body)
      expect(json['id']).to_not be_nil
      expect(json['title']).to eq('')
      expect(json['foo']).to be_nil
      expect(response.status).to eq(201)
      expect { Page.find(json['id']) }.to_not raise_error
    end

    it 'should not perform action of request if no user is signed in' do
      allow(controller).to receive(:doorkeeper_token).and_return(nil)
      process :create, method: :post, params: {
        title: 'foo',
        description: 'bar'
      }
      expect(response.status).to eq(401)
    end

    it 'should strip html from title and description fields before creating' do
      process :create, method: :post, params: {
        title: '<div>Hello World!</div>',
        description: '<p>This is a description with html</p>'
      }

      json = JSON.parse(response.body)
      page = Page.find(json['id'])
      expect(page.title).to eq('Hello World!')
      expect(page.description).to eq('This is a description with html')
    end

  end

  describe 'GET show' do

    it 'should fetch a page by id' do
      process :show, method: :get, params: {
        id: @page.id
      }
      json = JSON.parse(response.body)
      expect(json['id']).to eq(@page.id)
      expect(json['user']['username']).to eq(@page.user.username)
    end

    it 'should not return a page to a user who is not the owner if it is not published' do
      allow(controller).to receive(:current_user).and_return(new_user)
      process :show, method: :get, params: {
        id: @page.id
      }
      parse_response

      expect(response.status).to eq(403)
      expect(@res['errors']).to_not be_nil
    end

    it 'should return components associated with a page' do
      stub_serializers
      collection = ComponentCollection.new
      collection.components << new_audio_component
      collection.components << new_audio_component
      @page.components << collection
      @page.save

      collection = ComponentCollection.new
      collection.components = [new_image_component]
      @page.components << collection
      @page.save

      process :show, method: :get, params: {
        id: @page.id
      }

      json = JSON.parse(response.body)
      expect(json['components'].length).to eq(2)
    end

  end

  it 'should return a cover image for a page if there is one' do
    stub_serializers
    collection = ComponentCollection.new
    component = new_image_component
    collection.components << component
    @page.components << collection
    @page.save
    AddPageMetadataJob.perform_now(@page.id)

    process :show, method: :get, params: {
      id: @page.id
    }
    parse_response

    expect(@res['cover']).to_not be_nil
  end

  it 'should return type and media attributes of associated components' do
    collection = ComponentCollection.new
    collection.components << new_audio_component
    collection.components << new_audio_component
    @page.components << collection
    @page.save!

    process :show, method: :get, params: {
      id: @page.id
    }

    json = JSON.parse(response.body)
    collection = json['components'][0]
    component = collection['components'][0]
    expect(component['media_processing']).to eq(true)
  end

  it 'should return media attributes of non-uploaded media collections' do
    collection = ComponentCollection.new
    collection.components = [Component.new(media: 'foo')]
    @page.components << collection
    @page.save

    process :show, method: :get, params: {
      id: @page.id
    }

    json = JSON.parse(response.body)
    collection = json['components'][0]
    component = collection['components'][0]
    expect(component['media']).to eq('foo')
  end

  describe 'PUT update' do

    it 'should update a field of a page' do
      process :update, method: :put, params: {
        id: @page.id, title: 'New Title'
      }

      json = JSON.parse(response.body)
      expect(json['id']).to eq(@page.id)
      expect(json['title']).to eq('New Title')
      expect(@page.reload.title).to eq('New Title')
    end

    it 'should publish a page' do
      process :update, method: :put, params: {
        id: @page.id, published: true
      }

      json = JSON.parse(response.body)
      expect(json['published']).to eq(true)
      expect(@page.reload.published).to eq(true)
    end

    it 'should not update an invalid field' do
      views = @page.views.length
      process :update, method: :put, params: {
        id: @page.id, view_count: 1000000
      }
      json = JSON.parse(response.body)
      expect(json['views']).to eq(views)
      expect(@page.reload.views.length).to eq(views)
    end

    it 'should add tags via update' do
      process :update, method: :put, params: {
        id: @page.id,
        page: {
          title: 'New Title'
        },
        tags: %w(foo bar)
      }

      json = JSON.parse(response.body)
      expect(json['tags'].length).to eq(2)
      expect(@page.reload.tags.length).to eq(2)
    end

    it 'should overwrite existing tags on update' do
      process :update, method: :put, params: {
        id: @page.id,
        page: {
          title: 'New Title'
        },
        tags: %w(foo bar)
      }
      expect(@page.reload.tags.length).to eq(2)

      process :update, method: :put, params: {
        id: @page.id,
        page: {
          title: 'New Title'
        },
        tags: %w(foo baz qux)
      }

      json = JSON.parse(response.body)
      expect(json['tags'].length).to eq(3)
      expect(@page.reload.tags.length).to eq(3)
    end

    it 'should not update a page by a user who does not own the page' do
      (unauthor = new_user) and unauthor.save!
      allow(controller).to receive(:current_user).and_return(unauthor)
      process :update, method: :put, params: {
        id: @page.id, page: {
          name: 'New Name'
        }
      }
      expect(response.status).to eq(403)
    end

    it 'should strip html from title and description fields before updating' do
      process :update, method: :put, params: {
        id: @page.id,
        title: '<div>Hello World!</div>',
        description: '<p>This is a description with html</p>'
      }

      json = JSON.parse(response.body)
      page = Page.find(json['id'])
      expect(page.title).to eq('Hello World!')
      expect(page.description).to eq('This is a description with html')
    end

  end

  describe 'DELETE destroy' do
    it 'should destroy a page by id' do
      expect(Page.all.length).to eq(1)
      process :destroy, method: :delete, params: {
        id: @page.id
      }
      expect(response.status).to eq(200)
      expect(Page.all.length).to eq(0)
    end

    it 'should only destroy a page if the current user owns the page' do
      (unauthor = new_user) and unauthor.save!
      allow(controller).to receive(:current_user).and_return(unauthor)
      expect(Page.all.length).to eq(1)

      process :destroy, method: :delete, params: {
        id: @page.id
      }

      expect(response.status).to eq(403)
      expect(Page.all.length).to eq(1)
    end
  end
end
