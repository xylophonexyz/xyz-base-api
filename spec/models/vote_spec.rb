require 'rails_helper'

RSpec.describe Vote, type: :model do

  let(:tl_response) { double(:tl_response) }

  before :each do
    @page = new_page
    @user = new_user
    @user2 = new_user
    @user.save
    @user2.save
    @page.user = @user
    @page.save
    @vote = Vote.new(value: true)
  end

  it 'should create a vote' do
    @vote.user = @user2
    @vote.votable = @page
    expect(@vote).to be_valid
  end

  it 'should not create a vote without a user' do
    @vote.votable = @page
    expect(@vote).to_not be_valid
  end

  it 'should not create a vote without a votable association' do
    @vote.user = @user2
    expect(@vote).to_not be_valid
  end

  it 'should associate a vote with any object' do
    @comment = Comment.new
    @comment.commentable = @page
    @comment.user = @user2
    @comment.body = random_string
    @comment.save
    @vote.user = @user
    @comment.votes.push(@vote)
    expect(@comment.reload.votes.length).to eq(2)
  end

  it 'should not allow the same user to add more than one vote to a votable instance' do
    @vote.user = @user
    @page.votes << @vote
    expect(@page.reload.votes.length).to eq(1)
    expect(Vote.all.length).to eq(1)
  end

  it 'should provide methods to change a votes value' do
    @vote.user = @user2
    @page.votes.push(@vote)
    @vote.reload
    @vote.downvote
    expect(@vote.value).to eq(false)
    @vote.upvote
    expect(@vote.value).to eq(true)
  end

  it 'should destroy a vote when the associated user gets destroyed' do
    @vote.user = @user2
    @page.votes.push(@vote)
    expect(Vote.all.length).to eq(1)
    @user2.destroy
    expect(Vote.all.length).to eq(0)
  end

  it 'should return the vote given by a user' do
    @vote.user = @user2
    @page.votes.push(@vote)
    expect(@page.reload.votes.by_user(@user2).first).to eq(@vote)
  end
end
