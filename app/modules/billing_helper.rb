# frozen_string_literal: true

# Helper for Billing related logic
module BillingHelper
  require 'stripe'

  # determine if the current user has a valid billing account. a valid account must be within the trial period
  # or active and not past due
  def valid_billing_account?
    trial_period_active? || account_in_good_standing?
  end

  # update the total quantities the current user will be billed for over the current billing cycle
  def update_user_billing
    BillingQuantifierJob.perform_later(current_user.id) unless trial_period_active?
  end

  def trial_period_active?
    current_user.created_at + 30.days > Time.now
  end

  def account_in_good_standing?
    return false unless current_user.billing_account
    customer = Stripe::Customer.retrieve(current_user.billing_account.customer_id)
    customer.subscriptions.total_count.positive? && !customer.delinquent
  end
end
