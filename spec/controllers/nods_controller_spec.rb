require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe V1::NodsController do

  let(:user) { double :acceptable? => true }
  let(:token) { double :acceptable? => true }
  let(:tl_response) { double(:tl_response) }

  before :each do
    @nod = new_nod
    @page = new_page
    @user = new_user
    @user2 = new_user
    @user.save
    @user2.save
    @page.user = @user
    @page.save
    allow(controller).to receive(:set_current_user).and_return(nil)
    allow(controller).to receive(:authenticate_user!).and_return(user)
    allow(controller).to receive(:doorkeeper_token).and_return(token)
    allow(controller).to receive(:current_user).and_return(@user2)


  end

  describe 'POST create' do

    it 'should create a nod' do
      expect(Nod.all.length).to eq(0)
      expect(@page.nods.length).to eq(0)
      process :create, method: :post, params: {
        resource_id: @page.id, resource_type: 'Page'
      }
      json = JSON.parse(response.body)
      expect(response).to be_success
      expect(json['id']).to_not be_nil
      expect(Nod.all.length).to eq(1)
      expect(@page.reload.nods.length).to eq(1)
    end

    it 'should not create a nod with invalid params' do
      expect(Nod.all.length).to eq(0)
      process :create, method: :post, params: {
        resource_id: @page.id, resource_type: 'Jibberish'
      }
      json = JSON.parse(response.body)
      expect(json['errors']).to_not be_nil
      expect(response.status).to eq(400)
      expect(Nod.all.length).to eq(0)

      process :create, method: :post, params: {
        resource_id: 123123, resource_type: 'Page'
      }
      json = JSON.parse(response.body)
      expect(json['errors']).to_not be_nil
      expect(response.status).to eq(404)
    end

    it 'should fail if a user tries to create the same nod twice' do
      process :create, method: :post, params: {
        resource_id: @page.id, resource_type: 'Page'
      }
      expect(Nod.all.length).to eq(1)
      process :create, method: :post, params: {
        resource_id: @page.id, resource_type: 'Page'
      }
      expect(response.status).to eq(400)
    end

    it 'should not perform action of request if no user is signed in' do
      allow(controller).to receive(:doorkeeper_token).and_return(nil)
      process :create, method: :post, params: {
        resource_id: @page.id, resource_type: 'Page'
      }
      expect(response.status).to eq(401)
    end
  end

  describe 'DELETE destroy' do
    it 'should delete a nod' do
      process :create, method: :post, params: {
        resource_id: @page.id, resource_type: 'Page'
      }
      json = JSON.parse(response.body)
      id = json['id']
      expect(Nod.all.length).to eq(1)
      process :destroy, method: :delete, params: {
        id: id
      }
      expect(response).to be_success
      expect(Nod.all.length).to eq(0)
    end

    it 'should delete a nod if the user signed in did not create it' do
      # @user2 creates the nod
      process :create, method: :post, params: {
        resource_id: @page.id, resource_type: 'Page'
      }
      json = JSON.parse(response.body)
      id = json['id']
      expect(Nod.all.length).to eq(1)
      # @user tries to delete the nod
      allow(controller).to receive(:current_user).and_return(@user)
      process :destroy, method: :delete, params: {
        id: id
      }
      expect(response.status).to eq(403)
      expect(Nod.all.length).to eq(1)
    end

    it 'should not delete a nod that doesnt exist' do
      process :destroy, method: :delete, params: {
        id: 12312
      }
      expect(response.status).to eq(404)
    end

    it 'should not perform action of request if no user is signed in' do
      process :create, method: :post, params: {
        resource_id: @page.id, resource_type: 'Page'
      }
      json = JSON.parse(response.body)
      id = json['id']
      expect(Nod.all.length).to eq(1)
      allow(controller).to receive(:doorkeeper_token).and_return(nil)
      process :destroy, method: :delete, params: {
        id: id
      }
      expect(response.status).to eq(401)
    end
  end
end
