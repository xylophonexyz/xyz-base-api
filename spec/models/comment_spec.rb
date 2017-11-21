require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe Comment, type: :model do

  let(:tl_response) { double(:tl_response) }

  before :each do
    @page = new_page
    @page.save!
    @user = new_user
    @user.save!
    @comment = new_comment
    @comment.commentable = @page
    @comment.user = @user
  end

  it 'should save a comment' do
    expect(@comment).to be_valid
    expect(@comment.disabled).to eq(false)
  end

  it 'should not save a comment without a body' do
    @comment.body = nil
    expect(@comment).to_not be_valid
  end

  it 'should not save a comment without a parent' do
    @comment.commentable = nil
    expect(@comment).to_not be_valid
  end

  it 'should not save a comment without a user' do
    @comment.user = nil
    expect(@comment).to_not be_valid
  end

  it 'should store any model as parent' do
    @comment.commentable = new_audio_component
    expect(@comment).to be_valid
  end

  it 'should add a reply to a comment' do
    @comment.save
    @new_comment = new_comment
    @new_comment.commentable = @page
    @new_comment.user = @user
    @comment.add_reply(@new_comment)
    @comment.save
    expect(@comment.children.first).to eq(@new_comment)
  end

  it 'should expose a method to add a reply via a child' do
    @comment.save
    @new_comment = new_comment
    @new_comment.commentable = @page
    @new_comment.user = @user
    @new_comment.reply_to(@comment)
    expect(@comment.reload.children.first).to eq(@new_comment)
  end

  it 'should not add a reply to a non comment class' do
    @new_comment = new_comment
    @new_comment.commentable = @page
    @new_comment.user = @user
    expect{@new_comment.reply_to(new_audio_component)}.to raise_error('Parent is not a comment')
  end

  it 'should not add a reply to an invalid comment' do
    @comment.save
    @new_comment = new_comment
    @new_comment.user = @user
    expect{@comment.add_reply(@new_comment)}.to raise_error('Comment is not valid')
    expect{@comment.add_reply(new_audio_component)}.to raise_error('Comment is not valid')
  end

  it 'should soft destroy a comment' do
    @comment.save
    expect(Comment.all.length).to eq(1)
    @comment.destroy
    expect(Comment.all.length).to eq(1)
    expect(@comment.disabled).to eq(true)
  end

  it 'should update a comment' do
    @comment.save
    @comment.body = 'NEW BODY'
    @comment.save
    expect(@comment.reload.body).to eq('NEW BODY')
  end

  it 'should destroy a comment associated with a user when the user is destroyed' do
    @comment.save
    expect(Comment.first.disabled).to eq(false)
    expect(Comment.all.length).to eq(1)
    @user.destroy
    expect(Comment.all.length).to eq(1)
    expect(Comment.first.disabled).to eq(true)
  end

  it 'should auto upvote a comment once created' do
    @comment.save
    expect(@comment.votes.length).to eq(1)
    expect(@comment.votes.first.user).to eq(@comment.user)
    expect(@comment.votes.first.value).to eq(true)
  end

end
