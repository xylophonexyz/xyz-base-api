# frozen_string_literal: true

# Associates billing details via vendors (e.g. Stripe) with xyz users
class BillingAccount < ApplicationRecord
  belongs_to :user
  serialize :metadata
  validates_presence_of :customer_id
  validates_presence_of :user_id

  before_create :seed_metadata

  private

  def seed_metadata
    self.metadata ||= { active_subscriptions: [] }
  end
end
