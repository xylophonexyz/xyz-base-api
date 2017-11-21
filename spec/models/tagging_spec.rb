require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe Tagging, type: :model do

  it 'should associate a tag with a tagged object' do
    @tag = Tag.new(name: 'foo')
    @page = new_page
    @page.tags << @tag
    @page.save!
    @tagging = Tagging.first

    expect(Tag.all.length).to eq(1)
    expect(Tagging.all.length).to eq(1)
    expect(@tagging.taggable).to eq(@page)
    expect(@tagging.tag).to eq(@tag)
  end
end
