require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe V1::VotesController do

  let(:user) { double :acceptable? => true }
  let(:token) { double :acceptable? => true }
  let(:tl_response) { double(:tl_response) }

  before :each do
    @vote = new_vote
    @page = new_page
    @user = new_user
    @user2 = new_user
    @user.save
    @user2.save
    @page.user = @user
    @page.save!
    allow(controller).to receive(:set_current_user).and_return(nil)
    allow(controller).to receive(:authenticate_user!).and_return(user)
    allow(controller).to receive(:doorkeeper_token).and_return(token)
    allow(controller).to receive(:current_user).and_return(@user)


  end

  describe 'POST create' do
    it 'should create a vote' do
      @vote.value = true
      expect(Vote.all.length).to eq(0)
      expect(@page.votes.length).to eq(0)

      allow(controller).to receive(:current_user).and_return(@user2)
      process :create, method: :post, params: {
         resource_id: @page.id, resource_type: 'Page', value: true
      }
      json = JSON.parse(response.body)
      expect(response).to be_success
      expect(json['id']).to_not be_nil
      expect(Vote.all.length).to eq(1)
      expect(@page.reload.votes.length).to eq(1)
    end

    it 'should not create a vote with invalid params' do
      expect(Vote.all.length).to eq(0)
      process :create, method: :post, params: {
         resource_id: @page.id, resource_type: 'Jibberish'
      }
      json = JSON.parse(response.body)
      expect(json['errors']).to_not be_nil
      expect(response.status).to eq(400)
      expect(Vote.all.length).to eq(0)

      process :create, method: :post, params: {
         resource_id: 123123, resource_type: 'Page'
      }
      json = JSON.parse(response.body)
      expect(json['errors']).to_not be_nil
      expect(response.status).to eq(404)
    end

    it 'should not perform action of request if no user is signed in' do
      allow(controller).to receive(:doorkeeper_token).and_return(nil)
      process :create, method: :post, params: {
         resource_id: @page.id, resource_type: 'Page', value: true
      }
      expect(response.status).to eq(401)
    end
  end

  describe 'PUT update' do
    it 'should update a vote' do
      process :create, method: :post, params: {
         resource_id: @page.id, resource_type: 'Page', value: true
      }
      json = JSON.parse(response.body)
      expect(json['value']).to eq(true)
      id = json['id']
      process :update, method: :put, params: {
        id: id, value: false
      }
      json = JSON.parse(response.body)
      expect(json['value']).to eq(false)
    end

    it 'should update a vote for a user who does not own the vote' do
      process :create, method: :post, params: {
         resource_id: @page.id, resource_type: 'Page', value: true
      }
      json = JSON.parse(response.body)
      expect(json['value']).to eq(true)
      id = json['id']
      allow(controller).to receive(:current_user).and_return(@user2)
      process :update, method: :put, params: {
        id: id, value: false
      }
      expect(response.status).to eq(403)
    end

    it 'should auto cast to a boolean when a bad value is passed' do
      process :create, method: :post, params: {
         resource_id: @page.id, resource_type: 'Page', value: true
      }
      json = JSON.parse(response.body)
      expect(json['value']).to eq(true)
      id = json['id']

      process :update, method: :put, params: {
        id: id, value: 'evil value'
      }
      json = JSON.parse(response.body)
      expect(json['value']).to eq(true)
    end

    it 'should not update a vote with an unknown vote' do
      process :create, method: :post, params: {
         resource_id: @page.id, resource_type: 'Page', value: true
      }
      json = JSON.parse(response.body)
      expect(json['errors']).to be_nil

      process :update, method: :put, params: {
        id: 12312123, value: true
      }
      json = JSON.parse(response.body)
      expect(json['errors']).to_not be_nil
      expect(response.status).to eq(404)
    end

    it 'should not perform action of request if no user is signed in' do
      process :create, method: :post, params: {
         resource_id: @page.id, resource_type: 'Page', value: true
      }
      json = JSON.parse(response.body)
      expect(json['value']).to eq(true)
      id = json['id']
      allow(controller).to receive(:doorkeeper_token).and_return(nil)
      process :update, method: :put, params: {
        id: id, value: false
      }
      expect(response.status).to eq(401)
    end
  end
end
