require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe V1::CommentsController do

  let(:user) { double :acceptable? => true }
  let(:token) { double :acceptable? => true }
  let(:tl_response) { double(:tl_response) }

  before :each do
    @comment = new_comment
    @page = new_page
    @user = new_user
    @user2 = new_user
    @user.save
    @user2.save
    @page.user = @user
    @page.save
    @comment.user = @user2
    @page.comments << @comment
    @reply = new_comment
    @reply.commentable = @page
    @reply.user = @user
    allow(controller).to receive(:set_current_user).and_return(nil)
    allow(controller).to receive(:authenticate_user!).and_return(user)
    allow(controller).to receive(:doorkeeper_token).and_return(token)
    allow(controller).to receive(:current_user).and_return(@user2)


  end

  describe 'GET show' do
    it 'should return a comment tree starting with the root being the comment with id passed to the request' do
      process :show, method: :get, params: { id: @comment.id }
      json = JSON.parse(response.body)
      expect(json['id']).to eq(@comment.id)
      expect(json['children']).to eq([])
      @comment.add_reply(@reply)

      process :show, method: :get, params: { id: @comment.id }
      json = JSON.parse(response.body)
      expect(json['id']).to eq(@comment.id)
      expect(json['children'].first['id']).to eq(@reply.reload.id)
    end
  end

  describe 'POST create' do
    it 'should create a comment' do
      num_comments = Comment.all.length
      process :create, method: :post, params: {
        resource_id: @page.id, resource_type: 'page', body: 'Hello World'
      }
      json = JSON.parse(response.body)
      expect(json['id']).to_not be_nil
      expect(Comment.all.length).to eq(num_comments + 1)
      expect(json['body']).to eq('Hello World')
    end

    it 'should create a reply' do
      num_comments = Comment.all.length
      process :create, method: :post, params: {
          parent_id: @comment.id,
          body: 'Hello Reply'
      }
      json = JSON.parse(response.body)
      expect(json['id']).to_not be_nil
      expect(Comment.all.length).to eq(num_comments + 1)
      expect(json['body']).to eq('Hello Reply')
      expect(@comment.reload.children.length).to eq(1)
    end

    it 'should not perform action of request if no user is signed in' do
      allow(controller).to receive(:doorkeeper_token).and_return(nil)
      process :create, method: :post, params: {
        resource_id: @page.id, resource_type: 'page', body: 'Hello World'
      }
      expect(response.status).to eq(401)
    end

    it 'should not create an invalid comment' do
      num_comments = Comment.all.length
      process :create, method: :post, params: {
        resource_id: @page.id, resource_type: 'Jibberish', body: 'Hello World'
      }
      json = JSON.parse(response.body)
      expect(json['errors']).to_not be_nil
      expect(Comment.all.length).to eq(num_comments)

      process :create, method: :post, params: {
        resource_id: @page.id, resource_type: 'Page', body: ''
      }
      json = JSON.parse(response.body)
      expect(json['errors']).to_not be_nil
      expect(Comment.all.length).to eq(num_comments)

      process :create, method: :post, params: {
        resource_id: 1413123123, resource_type: 'Page', body: 'Hello World'
      }
      json = JSON.parse(response.body)
      expect(json['errors']).to_not be_nil
      expect(Comment.all.length).to eq(num_comments)
    end
  end

  describe 'PUT update' do
    it 'should update the body of a comment' do
      process :update, method: :put, params: {
        id: @comment.id,
        body: 'New Body'
      }
      json = JSON.parse(response.body)
      expect(json['body']).to eq('New Body')
      expect(@comment.reload.body).to eq('New Body')
    end

    it 'should not update a comment by a user who does not own the comment' do
      allow(controller).to receive(:current_user).and_return(@user)
      old_body = @comment.body
      process :update, method: :put, params: {
        id: @comment.id,
        body: 'New Body'
      }
      json = JSON.parse(response.body)
      expect(json['errors']).to_not be_nil
      expect(@comment.reload.body).to eq(old_body)
    end

    it 'should not perform action of request if no user is signed in' do
      allow(controller).to receive(:doorkeeper_token).and_return(nil)
      process :update, method: :put, params: {
        id: @comment.id,
        body: 'New Body'
      }
      expect(response.status).to eq(401)
    end
  end

  describe 'DELETE destroy' do
    it 'should soft delete a comment' do
      process :destroy, method: :delete, params: {
        id: @comment.id,
      }
      expect(response.status).to eq(200)
      expect(@comment.reload.disabled).to eq(true)
    end

    it 'should not delete a comment if the user making the request did not write the comment' do
      allow(controller).to receive(:current_user).and_return(@user)
      process :destroy, method: :delete, params: {
        id: @comment.id,
      }
      expect(response.status).to eq(403)
      expect(@comment.reload.disabled).to eq(false)
    end

    it 'should not perform action of request if no user is signed in' do
      allow(controller).to receive(:doorkeeper_token).and_return(nil)
      process :destroy, method: :delete, params: {
        id: @comment.id,
      }
      expect(response.status).to eq(401)
      expect(@comment.reload.disabled).to eq(false)
    end
  end

end
