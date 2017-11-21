require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe User, type: :model do

  let(:tl_response) { double(:tl_response) }

  before :each do
    @user = new_user
  end

  it 'should create a user' do
    @user.save
    expect(User.all.count).to eq(1)
  end

  # test disabled due to email based login and sign up
  # user can sign up with only an email address - they receive a confirmation link
  # and may add a username once they have logged in for the first time
  # it 'should not create a user without a username' do
  #   @user.username = ''
  #   expect(@user).to_not be_valid
  # end

  it 'should not create a user without an email' do
    @user.email = ''
    expect(@user).to_not be_valid
  end

  it 'should allow a user to set a bio' do
    bio = 'my bio'
    @user.bio = bio
    @user.save
    expect(@user.reload.bio).to eq(bio)
    end

  it 'should allow a user to set a first and last name' do
    first_name = 'jonny'
    last_name = 'appleseed'
    @user.first_name = first_name
    @user.last_name = last_name
    @user.save
    expect(@user.reload.first_name).to eq(first_name)
    expect(@user.reload.last_name).to eq(last_name)
  end

  it 'should allow a user to follow another user' do
    @kanye = new_user
    @user.save!
    @kanye.save!
    @user.follow(@kanye)
    expect(@user.following.length).to eq(1)
    expect(@kanye.followers.length).to eq(1)
    expect(@kanye.followers.include?(@user)).to eq(true)
  end

  it 'should allow a user to unfollow another user' do
    @kanye = new_user
    @user.save!
    @kanye.save!
    @user.follow(@kanye)
    expect(@user.following.length).to eq(1)
    expect(@kanye.followers.length).to eq(1)
    @user.unfollow(@kanye)
    expect(@kanye.reload.followers.length).to eq(0)
  end

  it 'should allow a user to follow herself' do
    @kanye = new_user
    @kanye.save
    @kanye.follow(@kanye)
    expect(@kanye.followers.length).to eq(1)
    expect(@kanye.followers.include?(@kanye)).to eq(true)
    expect(@kanye.following.include?(@kanye)).to eq(true)
  end
end
