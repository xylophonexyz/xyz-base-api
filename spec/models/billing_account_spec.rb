require 'rails_helper'
require 'model_helper'
include ModelHelper

RSpec.describe BillingAccount, type: :model do

  before :each do
    @user = new_user
    @user.save!
  end

  it 'should create a billing account' do
    billing_account = BillingAccount.new
    billing_account.user = @user
    billing_account.customer_id = SecureRandom.hex
    expect(BillingAccount.all.length).to eq(0)
    billing_account.save!
    expect(BillingAccount.all.length).to eq(1)
  end

  it 'should seed metadata object after creating' do
    billing_account = BillingAccount.new
    billing_account.user = @user
    billing_account.customer_id = SecureRandom.hex
    expect(BillingAccount.all.length).to eq(0)
    expect(billing_account.metadata).to be_nil
    billing_account.save!
    expect(billing_account.reload.metadata).to respond_to :[]
  end

  it 'should not overwrite existing metadata when seeding' do
    billing_account = BillingAccount.new
    billing_account.user = @user
    billing_account.customer_id = SecureRandom.hex
    billing_account.metadata = { foo: 'bar' }
    billing_account.save!
    expect(billing_account.reload.metadata).to eq({ foo: 'bar' })
  end

  it 'should not create a billing account without an associated user' do
    billing_account = BillingAccount.new
    billing_account.customer_id = SecureRandom.hex
    expect { billing_account.save! }.to raise_error(ActiveRecord::RecordInvalid)
    expect(BillingAccount.all.length).to eq(0)
  end

  it 'should not create a billing account without a customer id' do
    billing_account = BillingAccount.new
    billing_account.user = @user
    expect { billing_account.save! }.to raise_error(ActiveRecord::RecordInvalid)
    expect(BillingAccount.all.length).to eq(0)
  end
end
