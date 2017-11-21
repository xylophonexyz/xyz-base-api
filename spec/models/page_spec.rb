require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe Page, type: :model do

  let(:tl_response) { double(:tl_response) }

  before :each do
    @page = new_page
  end

  it 'should create a page' do
    @page.save
    expect(Page.all.count).to eq(1)
  end

  it 'should not create a page without a user' do
    @page.user = nil
    expect(@page).to_not be_valid
  end

  it 'should associate component collections with a page' do
    collection = ComponentCollection.new
    collection.components << new_audio_component
    collection.components << new_audio_component
    @page.component_collections << collection
    @page.save!
    expect(ComponentCollection.all.length).to eq(1)
    expect(Component.all.length).to eq(2)
    expect(Page.all.length).to eq(1)
    expect(@page.reload.component_collections.length).to eq(1)
  end

  it 'should alias components with component_collections' do
    collection = ComponentCollection.new
    collection.components << new_audio_component
    collection.components << new_audio_component
    @page.components << collection
    @page.save!
    expect(ComponentCollection.all.length).to eq(1)
    expect(Component.all.length).to eq(2)
    expect(Page.all.length).to eq(1)
    expect(@page.reload.component_collections.length).to eq(1)
  end

  it 'should destroy a page associated with a user when the user is destroyed' do
    @page.save!
    expect(Page.all.length).to eq(1)
    user = @page.user
    user.destroy
    expect(Page.all.length).to eq(0)
  end

  it 'should destroy associated component collections' do
    collection = ComponentCollection.new
    collection.components << new_audio_component
    collection.components << new_audio_component
    @page.components << collection
    @page.save!
    expect(ComponentCollection.all.length).to eq(1)
    expect(Component.all.length).to eq(2)
    expect(Page.all.length).to eq(1)

    @page.destroy

    expect(ComponentCollection.all.length).to eq(0)
    expect(Page.all.length).to eq(0)
  end

  it 'should keep track of views' do
    @page.save!
    @page.views << View.new(user: new_user)
    @page.save!
    expect(@page.views.length).to eq(1)
  end

  it 'should update a page with new values' do
    @page.save!
    @page = @page.reload

    @page.title = 'My Page'
    @page.description = 'Lorem ipsem'

    @page.save!
    expect(@page.reload.title).to eq('My Page')
    expect(@page.reload.description).to eq('Lorem ipsem')

    track = ComponentCollection.new
    track.components = [new_audio_component]
    @page.component_collections << track
    @page.save!

    expect(@page.components.length).to eq(1)
    expect(@page.components.first).to eq(track.reload)
  end
end
