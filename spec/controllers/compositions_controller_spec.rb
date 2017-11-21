require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe V1::CompositionsController, type: :controller do
  let(:user) { double :acceptable? => true }
  let(:token) { double :acceptable? => true }
  let(:tl_response) { double(:tl_response) }

  before :each do
    (@current_user = new_user) and @current_user.save!
    (@composition = new_composition) and (@composition.user = @current_user) and @composition.save

    @page = new_page
    collection = ComponentCollection.new
    collection.components << new_audio_component
    collection.components << new_audio_component
    @page.components << collection

    @composition.pages << @page
    @composition.save!

    allow(controller).to receive(:set_current_user).and_return(nil)
    allow(controller).to receive(:authenticate_user!).and_return(user)
    allow(controller).to receive(:doorkeeper_token).and_return(token)
    allow(controller).to receive(:current_user).and_return(@current_user)


  end

  describe 'GET index' do
    it 'should return a list of published compositions' do
      process :index, method: :get
      json = JSON.parse(response.body)
      expect(json.length).to eq(0)

      @composition.update!(published_on: Date.today)

      process :index, method: :get
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
    end

    it 'should return associated pages' do
      @composition.update!(published_on: Date.today)
      process :index, method: :get
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json[0]['pages'].length).to eq(1)
    end

    it 'should return compositions created by the current user' do
      # composition is not published and should still be returned since it belongs to the current user
      process :index_by_current_user, method: :get
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json[0]['pages'].length).to eq(1)

      other_user = new_user
      other_user.save
      allow(controller).to receive(:current_user).and_return(other_user)
      process :index_by_current_user, method: :get
      json = JSON.parse(response.body)
      expect(json.length).to eq(0)

      allow(controller).to receive(:authenticate_user!).and_return(nil)
      allow(controller).to receive(:doorkeeper_token).and_return(nil)

      process :index_by_current_user, method: :get
      expect(response.status).to eq(401)
    end
  end

  describe 'POST create' do

    it 'should create a composition' do
      process :create, method: :post, params: {
        title: 'foo'
      }
      expect(response.status).to eq(201)
      json = JSON.parse(response.body)
      expect(json['id']).to_not be_nil
      expect(Composition.all.length).to eq(2)
    end

    it 'should create a composition with a cover image component' do
      process :create, method: :post, params: {
        title: 'foo',
        add_cover: true
      }
      expect(response.status).to eq(201)
      json = JSON.parse(response.body)
      expect(json['cover']).to_not be_nil
      expect(Composition.all.length).to eq(2)
    end

    it 'should ignore the cover image if cover param is set to false' do
      process :create, method: :post, params: {
        title: 'foo',
        cover: false
      }
      expect(response.status).to eq(201)
      json = JSON.parse(response.body)
      expect(json['cover']).to be_nil
      expect(Composition.all.length).to eq(2)
    end

    it 'should create a composition with an associated parent' do
      parent = new_composition
      parent.save
      process :create, method: :post, params: {
        title: 'foo',
        cover: false,
        parent: parent.id
      }
      expect(response.status).to eq(201)
      json = JSON.parse(response.body)
      composition = Composition.find(json['id'])
      expect(composition.parent).to eq(parent)
    end

    it 'should ignore unknown parent ids on create' do
      process :create, method: :post, params: {
        title: 'foo',
        cover: false,
        parent: 123456
      }
      expect(response.status).to eq(201)
      json = JSON.parse(response.body)
      composition = Composition.find(json['id'])
      expect(composition.parent).to be_nil
    end

    it 'should not create a composition without a title' do
      process :create, method: :post, params: {
        title: ''
      }
      expect(response.status).to eq(400)
      json = JSON.parse(response.body)
      expect(json['errors']).to_not be_nil
      expect(Composition.all.length).to eq(1)
    end

    it 'should create a composition with a publish attribute' do
      process :create, method: :post, params: {
        title: 'foo',
        publish: true
      }
      expect(response.status).to eq(201)
      expect(Composition.all.length).to eq(2)
      expect(Composition.all.last.published?).to eq(true)
    end

    it 'should create a composition with a publish attribute set to false' do
      process :create, method: :post, params: {
          title: 'foo',
          publish: false
      }
      expect(response.status).to eq(201)
      expect(Composition.all.length).to eq(2)
      expect(Composition.all.last.published?).to eq(false)
    end

    it 'should strip html from title before creating' do
      process :create, method: :post, params: {
        title: '<div>Hello World!</div>'
      }
      json = JSON.parse(response.body)
      composition = Composition.find(json['id'])
      expect(composition.title).to eq('Hello World!')
    end

  end

  describe 'linking and unlinking pages' do

    it 'should link a page to an existing composition' do
      # POST /compositions/:composition_id/pages/:page_id
      page = new_page
      page.user = @current_user
      page.save!
      process :link_page, method: :post, params: {
        composition_id: @composition.id,
        page_id: page.id
      }
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['pages'].length).to eq(2)
      expect(@composition.pages.length).to eq(2)
    end

    it 'should not link a page if the composition and page arent owned by the same user' do
      page = new_page
      page.user = new_user
      page.save!

      process :link_page, method: :post, params: {
        composition_id: @composition.id,
        page_id: page.id
      }
      expect(response.status).to eq(403)
      expect(@composition.pages.length).to eq(1)
    end

    it 'should unlink a page from a composition' do
      page = new_page
      page.composition = @composition
      page.user = @current_user
      page.save!

      process :unlink_page, method: :delete, params: {
        composition_id: @composition.id,
        page_id: page.id
      }
      expect(response.status).to eq(200)
      expect(@composition.pages.length).to eq(1)
    end

    it 'should not unlink a page if the composition and page are not owned by the same user' do
      # manually set association between page and composition
      # composition is created by @current user, page is created by new_user
      page = new_page
      page.composition = @composition
      page.user = new_user
      page.save!
      # try to unlink, there is a mismatch between owners. the owner of composition and page need to be the same
      # to perform unlink operation, a 403 should be returned (forbidden)
      process :unlink_page, method: :delete, params: {
        composition_id: @composition.id,
        page_id: page.id
      }
      expect(response.status).to eq(403)
      expect(@composition.pages.length).to eq(2)
      expect(page.reload.composition).to eq(@composition)
    end

    it 'should not unlink a page if the page is not already linked to the composition' do
      page = new_page
      page.user = @current_user
      page.composition = new_composition
      page.save!

      process :unlink_page, method: :post, params: {
        composition_id: @composition.id,
        page_id: page.id
      }
      expect(response.status).to eq(400)
      expect(@composition.pages.length).to eq(1)
      expect(page.reload.composition).to_not eq(@composition)
    end
  end

  describe 'GET show' do
    it 'should return a published composition' do
      @composition.update(published_on: Time.now)
      process :show, method: :get, params: {
        id: @composition.id
      }

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['id']).to_not be_nil
    end

    it 'should return an unpublished composition to the user who created it' do
      process :show, method: :get, params: {
        id: @composition.id
      }

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['id']).to_not be_nil

    end

    it 'should not return an unpublished composition to any user other than who created it' do
      allow(controller).to receive(:current_user).and_return(new_user)
      process :show, method: :get, params: {
        id: @composition.id
      }

      expect(response.status).to eq(403)
      json = JSON.parse(response.body)
      expect(json['errors']).to_not be_nil
    end

    it 'should return a 404 for unknown composition id' do
      process :show, method: :get, params: {
        id: 123123
      }

      expect(response.status).to eq(404)
      json = JSON.parse(response.body)
      expect(json['errors']).to_not be_nil
    end

    it 'should return pages associated with a composition' do
      @composition.update(published_on: Time.now)
      process :show, method: :get, params: {
        id: @composition.id
      }

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['pages'].length).to eq(1)
    end

    it 'should return published pages associated with a composition if the requesting user is not the author' do
      allow(controller).to receive(:current_user).and_return(new_user)
      @composition.update(published_on: Time.now)
      process :show, method: :get, params: {
        id: @composition.id
      }

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['pages'].length).to eq(0)
    end

    it 'should return the associated parent' do
      parent = new_composition
      parent.save!
      @composition.parent = parent
      @composition.save!
      process :show, method: :get, params: {
        id: @composition.id
      }

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['parent']['id']).to eq(parent.id)
    end

    it 'should return associated child compositions' do
      parent = new_composition
      parent.user = @current_user
      parent.save!
      @composition.parent = parent
      @composition.save!
      process :show, method: :get, params: {
        id: parent.id
      }

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['compositions'].length).to eq(1)
      expect(json['compositions'][0]['id']).to eq(@composition.id)
    end

  end

  describe 'PUT update' do
    it 'should update a composition by the user who created it' do
      process :update, method: :put, params: {
        id: @composition.id,
        publish: 'true'
      }

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['published_on']).to_not be_nil
      expect(@composition.reload.published?).to eq(true)

      process :update, method: :put, params: {
        id: @composition.id,
        title: 'New Title'
      }

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['title']).to eq('New Title')
    end

    it 'should remove a cover image from a composition' do
      @composition.image = ComponentCollection.new(components: [ImageComponent.new])
      process :update, method: :put, params: {
        id: @composition.id,
        remove_cover: true,
        publish: true
      }

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['published_on']).to_not be_nil
      expect(@composition.reload.published?).to eq(true)
      expect(@composition.reload.cover).to eq(nil)

      process :update, method: :put, params: {
        id: @composition.id,
        title: 'New Title'
      }

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['title']).to eq('New Title')
    end

    it 'should not update a composition by a user who did not create it' do
      allow(controller).to receive(:current_user).and_return(new_user)

      process :update, method: :put, params: {
        id: @composition.id,
        publish: 'true'
      }

      expect(response.status).to eq(403)
      json = JSON.parse(response.body)
      expect(json['errors']).to_not be_nil
    end

    it 'should update a composition with an associated parent' do
      parent = new_composition
      parent.save
      process :update, method: :put, params: {
        id: @composition.id,
        parent: parent.id
      }
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      composition = Composition.find(json['id'])
      expect(composition.parent).to eq(parent)
    end

    it 'should ignore unknown parent ids on update' do
      process :update, method: :put, params: {
        id: @composition.id,
        parent: 12345
      }
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      composition = Composition.find(json['id'])
      expect(composition.parent).to be_nil
    end

    it 'should return a 404 for an unknown composition id' do
      process :update, method: :put, params: {
        id: 43152,
        publish: true
      }

      expect(response.status).to eq(404)
      json = JSON.parse(response.body)
      expect(json['errors']).to_not be_nil
    end

    it 'should return a 401 if there is no user signed in' do
      allow(controller).to receive(:authenticate_user!).and_return(nil)
      allow(controller).to receive(:doorkeeper_token).and_return(nil)
      allow(controller).to receive(:current_user).and_return(nil)

      process :update, method: :put, params: {
        id: 43152,
        publish: 'true'
      }

      expect(response.status).to eq(401)
      expect(response.body).to be_empty
    end

    it 'should update the title' do
      process :update, method: :put, params: {
        id: @composition.id,
        title: 'Foobarred'
      }

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['title']).to eq('Foobarred')
      expect(@composition.reload.pages.length).to eq(1)
      expect(@composition.reload.published?).to eq(true)
    end

    it 'should update the published_on attribute' do
      process :update, method: :put, params: {
        id: @composition.id,
        publish: 'true'
      }

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['published_on']).to_not be_nil
      expect(json['pages'].length).to eq(1)
      expect(@composition.reload.pages.length).to eq(1)
      expect(@composition.reload.published?).to eq(true)
    end

    it 'should update metadata' do
      process :update, method: :put, params: {
        id: @composition.id,
        metadata: {
          foo: 'bar'
        }
      }

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['metadata']).to_not be_nil
      expect(json['metadata']['foo']).to eq('bar')
    end

    it 'should not overwrite metadata unless the `metadata` key is present' do
      process :update, method: :put, params: {
        id: @composition.id,
        metadata: {
          foo: 'bar'
        }
      }
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['metadata']).to_not be_nil
      expect(json['metadata']['foo']).to eq('bar')

      process :update, method: :put, params: {
        id: @composition.id,
        title: 'Foo'
      }
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['metadata']).to_not be_nil
      expect(json['metadata']['foo']).to eq('bar')
      expect(json['title']).to eq('Foo')
    end

    it 'should not update pages' do
      process :update, method: :put, params: {
        id: @composition.id,
        pages: [
          1, 2, 4
        ],
        publish: 'true',
        title: 'Foo'
      }

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['pages'].length).to eq(1)
      expect(@composition.reload.pages.length).to eq(1)
      expect(@composition.reload.published?).to eq(true)
    end

    it 'should strip html from title when updating' do
      process :update, method: :put, params: {
        id: @composition.id,
        title: '<div>Hello World!</div>'
      }
      json = JSON.parse(response.body)
      composition = Composition.find(json['id'])
      expect(composition.title).to eq('Hello World!')
    end
  end

  describe 'DELETE destroy' do
    it 'should destroy a composition by the user who created it' do
      process :destroy, method: :delete, params: {
        id: @composition.id
      }
      expect(response.status).to eq(200)
      expect(response.body).to be_empty
      expect(Composition.all.length).to eq(0)
    end

    it 'should return a 404 for an unknown composition id' do
      process :destroy, method: :delete, params: {
        id: 43152
      }

      expect(response.status).to eq(404)
      json = JSON.parse(response.body)
      expect(json['errors']).to_not be_nil
    end

    it 'should return a 401 if there is no user signed in' do
      allow(controller).to receive(:authenticate_user!).and_return(nil)
      allow(controller).to receive(:doorkeeper_token).and_return(nil)
      allow(controller).to receive(:current_user).and_return(nil)

      process :destroy, method: :delete, params: {
        id: @composition.id
      }

      expect(response.status).to eq(401)
      expect(response.body).to be_empty
    end

    it 'should not destroy a composition if the current user is not the author' do
      allow(controller).to receive(:current_user).and_return(new_user)

      process :destroy, method: :delete, params: {
        id: @composition.id
      }

      expect(response.status).to eq(403)
      json = JSON.parse(response.body)
      expect(json['errors']).to_not be_nil
      expect(Composition.all.length).to eq(1)
    end

    it 'should destroy associated pages' do
      expect(Page.all.length).to eq(1)
      process :destroy, method: :delete, params: {
        id: @composition.id
      }
      expect(Page.all.length).to eq(0)
    end
  end
end

