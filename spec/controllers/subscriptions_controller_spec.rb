require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe V1::SubscriptionsController, type: :controller do
  let(:user) { double :acceptable? => true }
  let(:token) { double :acceptable? => true }
  let(:tl_response) { double(:tl_response) }

  before :each do
    (@current_user = new_user) and @current_user.save!
    (@page = new_page) and (@page.user = @current_user) and @page.save

    allow(controller).to receive(:set_current_user).and_return(nil)
    allow(controller).to receive(:authenticate_user!).and_return(user)
    allow(controller).to receive(:doorkeeper_token).and_return(token)
    allow(controller).to receive(:current_user).and_return(@current_user)
  end

  describe 'POST create' do

    it 'should create a billing account and subscription in stripe' do
      process :create, method: :post, params: {
        stripeToken: 'tok_visa',
        stripeEmail: 'foo@example.com',
        stripeBillingName: 'Foo Bar',
        stripeBillingAddressLine1: '123 Any Street',
        stripeBillingAddressZip: '123456',
        stripeBillingAddressCity: 'San Francisco',
        stripeBillingAddressCountry: 'United States'
      }

      expect(response.status).to eq(201)
      json = JSON.parse(response.body)
      expect(json['customer_id']).to_not be_nil
      expect(json['metadata']).to_not be_nil
      expect(@current_user.reload.billing_account).to_not be_nil
    end

    it 'should provide error messages when creating a subscription fails' do
      process :create, method: :post, params: {
        stripeToken: 'invalid token',
        stripeEmail: 'foo@example.com',
        stripeBillingName: 'Foo Bar',
        stripeBillingAddressLine1: '123 Any Street',
        stripeBillingAddressZip: '123456',
        stripeBillingAddressCity: 'San Francisco',
        stripeBillingAddressCountry: 'United States'
      }

      json = JSON.parse(response.body)
      expect(response.status).to eq(400)
      expect(json['errors']).to_not be_nil
      expect(@current_user.reload.billing_account).to be_nil
    end

  end

  describe 'DELETE destroy' do

    it 'should destroy an existing billing account' do
      process :create, method: :post, params: {
        stripeToken: 'tok_visa',
        stripeEmail: 'foo@example.com',
        stripeBillingName: 'Foo Bar',
        stripeBillingAddressLine1: '123 Any Street',
        stripeBillingAddressZip: '123456',
        stripeBillingAddressCity: 'San Francisco',
        stripeBillingAddressCountry: 'United States'
      }

      json = JSON.parse(response.body)
      expect(response.status).to eq(201)
      expect(json['customer_id']).to_not be_nil
      expect(@current_user.reload.billing_account).to_not be_nil

      process :destroy, method: :delete
      expect(response.status).to eq(200)
      expect(@current_user.reload.billing_account).to be_nil

    end

    it 'should return errors if attempting an action that produces an error in stripe' do
      process :create, method: :post, params: {
        stripeToken: 'tok_visa',
        stripeEmail: 'foo@example.com',
        stripeBillingName: 'Foo Bar',
        stripeBillingAddressLine1: '123 Any Street',
        stripeBillingAddressZip: '123456',
        stripeBillingAddressCity: 'San Francisco',
        stripeBillingAddressCountry: 'United States'
      }
      expect(response.status).to eq(201)
      @current_user.reload.billing_account.customer_id = 'foo'
      @current_user.save

      process :destroy, method: :delete
      json = JSON.parse(response.body)
      expect(response.status).to eq(400)
      expect(json['errors']).to_not be_nil
      expect(@current_user.reload.billing_account).to_not be_nil
    end

    it 'should return errors if attempting to remove a billing account that doesnt exist' do
      expect(@current_user.reload.billing_account).to be_nil

      process :destroy, method: :delete
      json = JSON.parse(response.body)
      expect(response.status).to eq(400)
      expect(json['errors']).to_not be_nil
      expect(@current_user.reload.billing_account).to be_nil
    end

  end
end
