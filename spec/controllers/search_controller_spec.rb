require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe V1::SearchController do

  let(:user) { double :acceptable? => true }
  let(:token) { double :acceptable? => true }
  let(:tl_response) { double(:tl_response) }

  before :each do
    @nod = new_nod
    @page = new_page
    @user = new_user
    @user2 = new_user
    @user.save
    @user2.save
    @page.user = @user
    @page.save
    allow(controller).to receive(:set_current_user).and_return(nil)
    allow(controller).to receive(:authenticate_user!).and_return(user)
    allow(controller).to receive(:doorkeeper_token).and_return(token)
    allow(controller).to receive(:current_user).and_return(@user2)


  end

  describe 'POST search' do
    it 'should search on a query' do
      process :search, method: :post, params: {
        query: @user2.username
      }
      json = JSON.parse(response.body)
      expect(response).to be_success
      expect(json).to_not be_empty
    end
  end

end
