require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe Composition, type: :model do

  let(:tl_response) { double(:tl_response) }

  before :each do
    @composition = new_composition
  end

  it 'should create a composition' do
    expect(@composition).to be_valid
    @composition.save!

    expect(Composition.all.length).to eq(1)
    expect(@composition.reload.title).to_not be_nil
  end

  it 'should not create a composition without an associated user' do
    @composition.user = nil
    expect(@composition).to_not be_valid
  end

  it 'should associate pages with a composition' do
    @composition.pages << new_page
    @composition.pages << new_page
    expect(@composition).to be_valid
    @composition.save!

    expect(Composition.all.length).to eq(1)
    expect(Page.all.length).to eq(2)
    expect(@composition.reload.pages.length).to eq(2)
  end

  it 'should add a json object to a composition' do
    @composition.metadata = { foo: 'bar' }
    @composition.save!
    expect(@composition.metadata[:foo]).to eq('bar')
  end

  it 'should support adding a background image' do
    cover = ComponentCollection.new
    cover.components << new_image_component
    @composition.image = cover
    @composition.save!

    expect(@composition.cover).to_not be_nil
  end

  it 'should update a composition' do
    @composition.save!
    @composition = @composition.reload
    @composition.title = 'Modified Title'
    @composition.save!
    expect(@composition.reload.title).to eq('Modified Title')

    old_cover = @composition.cover
    @composition.image = ComponentCollection.new(components: [new_image_component])
    @composition.save!
    expect(@composition.reload.cover).to_not eq(old_cover)
  end

  it 'should set a publish date for a composition' do
    @composition.published_on = Date.today
    @composition.save!
    Timecop.freeze(Date.today + 30) do
      expect(@composition.reload.published_on).to be < Date.today
    end
  end

  it 'should provide a method to determine if a composition has been published' do
    expect(@composition.published?).to eq(false)

    @composition.published_on = Date.today
    @composition.save!

    expect(@composition.reload.published?).to eq(true)
  end

  it 'should destroy a composition and all associated pages' do
    collection = ComponentCollection.new
    collection.components << new_audio_component
    collection.components << new_audio_component
    v1 = new_page
    v2 = new_page
    v1.components << collection
    collection = ComponentCollection.new
    collection.components << new_image_component
    collection.components << new_image_component
    v2.components << collection
    @composition.pages << v1
    @composition.pages << v2
    @composition.save!

    expect(Page.all.length).to eq(2)
    expect(ComponentCollection.all.length).to eq(2)
    expect(Component.all.length).to eq(4)
    expect(Composition.all.length).to eq(1)

    @composition.destroy

    expect(Page.all.length).to eq(0)
    expect(Composition.all.length).to eq(0)
    expect(ComponentCollection.all.length).to eq(0)
    expect(Component.all.length).to eq(0)
  end

  it 'should allow a composition to add another composition as a parent' do
    parent = new_composition
    parent.save
    expect(parent.parent).to be_nil
    child = new_composition
    child.parent = parent
    child.save!
    expect(child.reload.parent).to eq(parent)
  end

  it 'should not allow for circular references of compositions' do
    parent = new_composition
    parent.parent = parent
    expect(parent).to_not be_valid
  end

  it 'should return associations from child to parent' do
    parent = new_composition
    parent.save!
    @composition.parent = parent
    @composition.save
    expect(@composition.parent).to eq(parent)
  end

  it 'should return associations from parent to child' do
    parent = new_composition
    parent.save!
    @composition.parent = parent
    @composition.save
    expect(parent.compositions.length).to eq(1)
    expect(parent.compositions.first).to eq(@composition)
  end

end
