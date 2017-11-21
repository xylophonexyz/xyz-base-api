require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe Nod, type: :model do

  let(:tl_response) { double(:tl_response) }

  before :each do
    @page = new_page
    @user = new_user
    @user2 = new_user
    @user.save
    @user2.save
    @page.user = @user
    @page.save
    @nod = Nod.new
  end

  it 'should create a nod' do
    @nod.user = @user2
    @page.nods.push(@nod)
    expect(@page.nods.length).to eq(1)
  end

  it 'should not allow a user to nod more than once on the same noddable instance' do
    @nod.user = @user
    @page.nods.push(@nod)
    expect(@page.reload.nods.length).to eq(1)
    @nod = Nod.new
    @nod.user = @user
    @page.nods.push(@nod)
    expect(@page.reload.nods.length).to eq(1)
    expect(Nod.all.length).to eq(1)
  end

  it 'should return the nod given by a user' do
    @nod.user = @user2
    @page.nods.push(@nod)
    expect(@page.reload.nods.by_user(@user2).first).to eq(@nod)
  end

  it 'should destroy a nod when the associated user gets destroyed' do
    @nod.user = @user2
    @page.nods.push(@nod)
    expect(Nod.all.length).to eq(1)
    @user2.destroy
    expect(Nod.all.length).to eq(0)
  end
end
