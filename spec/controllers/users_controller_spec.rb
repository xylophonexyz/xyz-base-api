require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe V1::UsersController do

  let(:user) { double :acceptable? => true }
  let(:token) { double :acceptable? => true }
  let(:tl_response) { double(:tl_response) }

  before :each do
    @user = new_user
    @user2 = new_user
    @user.save
    @user2.save
    allow(controller).to receive(:set_current_user).and_return(nil)
    allow(controller).to receive(:authenticate_user!).and_return(user)
    allow(controller).to receive(:doorkeeper_token).and_return(token)
    allow(controller).to receive(:current_user).and_return(@user)


  end

  describe 'GET show' do
    it 'should return a user' do
      process :show, method: :get, params: {
        id: @user.id
      }
      json = JSON.parse(response.body)
      expect(json['username']).to eq(@user.username)
    end

    it 'should return a user in the format defined by UserSerializer' do
      process :show, method: :get, params: {
        id: @user.id
      }
      user = JSON.parse(response.body)
      expect(user['username']).to eq(@user.username)
      expect(user['email']).to eq(@user.email)
      expect(user['first_name']).to eq(@user.first_name)
      expect(user['last_name']).to eq(@user.last_name)
      expect(user['followers']).to eq(@user.followers)
      expect(user['following']).to eq(@user.following)
      expect(user['session']).to_not be_nil
    end

    it 'should return a user when a username is provided' do
      process :show, method: :get, params: {
        id: @user.username
      }
      json = JSON.parse(response.body)
      expect(json['id']).to eq(@user.id)
    end

    it 'should return the user found by id when id matches username' do
      user = new_user
      user.username = 1
      user.save!
      expect(@user.id.to_s).to eq(user.username)

      process :show, method: :get, params: {
        # user.username is == @user.id
        id: user.username
      }
      json = JSON.parse(response.body)
      expect(json['id']).to eq(@user.id)
    end

    it 'should return the user found by username when username is explicitly specified' do
      user = new_user
      user.username = 1
      user.save!
      expect(@user.id.to_s).to eq(user.username)

      process :show, method: :get, params: {
        id: user.username,
        use_username: true
      }
      json = JSON.parse(response.body)
      expect(json['id']).to eq(user.id)
    end

    it 'should return the user found by id when id is explicitly specified' do
      user = new_user
      user.username = 1
      user.save!
      expect(@user.id.to_s).to eq(user.username)

      process :show, method: :get, params: {
        id: user.username,
        use_id: true
      }
      json = JSON.parse(response.body)
      expect(json['id']).to eq(@user.id)
    end
  end

  describe 'PUT update' do
    it 'should update a users information' do
      # update username
      process :update, method: :put, params: {
        id: @user.username, username: 'john'
      }
      user = JSON.parse(response.body)
      expect(user['username']).to eq('john')
      expect(@user.reload.username).to eq('john')
    end

    it 'should update a users additional metadata' do
      # add an external (social media) connection
      connections = { connections: [{ name: 'twitter', url: 'http://twitter.com/john' }] }
      process :update, method: :put, params: {
        id: @user.username, metadata: connections
      }
      user = JSON.parse(response.body)
      expect(user['metadata']['connections'][0]['url']).to eq('http://twitter.com/john')
      expect(@user.reload.metadata['connections'].first[:name]).to eq(connections[:connections][0][:name])

      connections = { connections: [{ name: 'medium', url: 'http://medium.com/john' }] }
      process :update, method: :put, params: {
        id: @user.username, metadata: connections
      }
      user = JSON.parse(response.body)
      expect(user['metadata']['connections'][0]['name']).to eq('medium')
      expect(user['metadata']['connections'][0]['url']).to eq('http://medium.com/john')
      expect(@user.reload.metadata['connections'].first[:name]).to eq(connections[:connections][0][:name])

      connections = {
        connections: [
          { name: 'medium', url: 'http://medium.com/john' },
          { name: 'twitter', url: 'http://twitter.com/john' }
        ]
      }

      process :update, method: :put, params: {
        id: @user.username, metadata: connections
      }
      user = JSON.parse(response.body)
      expect(user['metadata']['connections'][1]['name']).to eq('twitter')
      expect(user['metadata']['connections'][1]['url']).to eq('http://twitter.com/john')
      expect(user['metadata']['connections'][0]['name']).to eq('medium')
      expect(user['metadata']['connections'][0]['url']).to eq('http://medium.com/john')
      expect(@user.reload.metadata['connections'].first[:name]).to eq(connections[:connections][0][:name])
      expect(@user.reload.metadata['connections'].last[:name]).to eq(connections[:connections][1][:name])
    end

    it 'should not overwrite an existing metadata object' do
      connections = { connections: [
        {name: 'medium', url: 'http://medium.com/john'},
        {name: 'twitter', url: 'http://twitter.com/john'}
      ] }
      process :update, method: :put, params: {
        id: @user.username, metadata: connections
      }
      user = JSON.parse(response.body)
      expect(user['metadata']['connections'][1]['url']).to eq('http://twitter.com/john')
      # should update first, leave the second the same, add the third as new
      stripe = { stripe: { access_token: '1234' } }
      process :update, method: :put, params: {
        id: @user.username, metadata: stripe
      }
      user = JSON.parse(response.body)
      expect(user['metadata']['connections'][0]['url']).to eq('http://medium.com/john')
      expect(user['metadata']['connections'][1]['url']).to eq('http://twitter.com/john')
      expect(user['metadata']['stripe']).to_not be_nil
    end

    it 'should allow a user to update their avatar' do
      allow_any_instance_of(V1::UsersController)
        .to receive(:update_avatar).and_return('avatar')
      process :update_avatar, method: :post, params: {
        user_id: @user.username, image_data_url: 'some bytes'
      }
      expect(response).to be_success
    end

  end

  describe 'GET check' do
    it 'should check if a username is taken' do
      process :check, method: :post, params: {
        username: 'john'
      }
      expect(response).to_not be_success

      process :update, method: :put, params: {
        id: @user.username, username: 'john'
      }

      process :check, method: :post, params: {
        username: 'john'
      }
      expect(response).to be_success
    end

    it 'should check if an email is taken' do
      process :check, method: :post, params: {
        email: 'john@example.com'
      }
      expect(response).to_not be_success

      process :update, method: :put, params: {
        id: @user.username, email: 'john@example.com'
      }

      process :check, method: :post, params: {
        email: 'john@example.com'
      }
      expect(response).to be_success
    end
  end

  describe 'POST follow/unfollow' do
    it 'should allow a user to follow another user' do
      expect(@user2.followers.length).to eq(0)
      process :follow, method: :post, params: {
        user_id: @user2.id
      }
      expect(response).to be_success
      json = JSON.parse(response.body)
      # return the user who is now followed
      expect(json['username']).to eq(@user2.username)
      expect(@user2.reload.followers.length).to eq(1)
    end

    it 'should allow a user to unfollow another user' do
      process :follow, method: :post, params: {
        user_id: @user2.id
      }
      expect(@user2.reload.followers.length).to eq(1)
      expect(@user.reload.following.length).to eq(1)

      process :unfollow, method: :post, params: {
        user_id: @user2.id
      }
      # return the user who is now followed
      json = JSON.parse(response.body)
      expect(response).to be_success
      expect(json['username']).to eq(@user2.username)
      expect(@user2.reload.followers.length).to eq(0)
      expect(@user.reload.following.length).to eq(0)
    end
  end

  describe 'DELETE destroy' do
    it 'should allow a user to delete their account' do
      count = User.all.count
      process :destroy, method: :delete, params: {
          id: @user.id
      }
      expect(response).to be_success
      expect(User.all.count).to eq(count - 1)
    end

    it 'should only allow the signed in user to delete their own account' do
      allow(controller).to receive(:authenticate_user!).and_return(nil)
      allow(controller).to receive(:current_user).and_return(nil)
      count = User.all.count
      process :destroy, method: :delete, params: {
          id: @user.id
      }
      expect(response).to_not be_success
      expect(User.all.count).to eq(count)
    end
  end

end
