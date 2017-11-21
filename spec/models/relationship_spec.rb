require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe Relationship, type: :model do

  let(:tl_response) { double(:tl_response) }

  before :each do
    @user = new_user
    @user.save!
    @kanye = new_user
    @kanye.save!
    @relationship = Relationship.new(follower_id: @user.id, followed_id: @kanye.id)
  end

  it 'should be valid' do
    expect(@relationship).to be_valid
  end

  it 'should require a follower id' do
    @relationship.follower_id = nil
    expect(@relationship).to_not be_valid
  end

  it 'should require a followed id' do
    @relationship.followed_id = nil
    expect(@relationship).to_not be_valid
  end
end
