require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe Tag, type: :model do

  it 'should create a tag with a name' do
    @tag = Tag.new(name: 'foo')
    expect(@tag).to be_valid
    @tag.save!
    expect(Tag.all.length).to eq(1)
  end

  it 'should not create a tag without a name' do
    @tag = Tag.new
    expect(@tag).to_not be_valid
  end

  it 'should not create a tag without a valid name' do
    @tag = Tag.new(name: '!@@#!@#SDFSDF')
    expect(@tag).to_not be_valid
  end

  it 'should not create a new tag with an identical name, instead it should return the tag that exists already' do
    @tag = Tag.new(name: 'foo')
    @tag.save!
    @tag = Tag.new(name: 'foo')
    expect(@tag).to eq(Tag.first)
  end

  it 'should support searching' do
    expect(Tag).to respond_to(:search)
  end

  it 'should return associated taggable object on search' do
    @page = new_page
    @tag = Tag.new(name: 'foo')
    @page.tags << @tag
    @page.save!
    results = Tag.search('foo')
    expect(results).to include(@page)
  end

end
