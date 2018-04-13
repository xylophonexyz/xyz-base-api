# frozen_string_literal: true

require 'stripe'

module V1
  # Handle creation and deletion of billing subscriptions for user accounts
  class SubscriptionsController < ApplicationController

    def create
      create_customer
      create_subscription
      create_billing_account
      current_user.save
      render json: @account, status: :created
    rescue Stripe::InvalidRequestError => error
      render json: { errors: [error.message] }, status: :bad_request
    end

    def destroy
      unless current_user.billing_account
        return render json: { errors: ['Could not find associated billing account'] }, status: 400
      end
      customer = Stripe::Customer.retrieve(current_user.billing_account.customer_id)
      if customer.delete
        current_user.billing_account = nil
        current_user.save
        head :ok
      else
        render json: { errors: ['An error occurred when attempting to delete the billing account'] },
               status: :bad_request
      end
    rescue Stripe::InvalidRequestError => error
      render json: { errors: [error.message] }, status: :bad_request
    end

    private

    def create_customer
      @customer = Stripe::Customer.create(
        description: "billing account for user #{current_user.email}",
        source: subscription_params[:stripeToken]
      )
    end

    def create_billing_account
      @account = BillingAccount.new(user: current_user)
      @account.metadata = {
        billing_name: subscription_params[:stripeBillingName],
        billing_address_line_1: subscription_params[:stripeBillingAddressLine1],
        billing_address_line_2: subscription_params[:stripeBillingAddressLine2],
        billing_address_zip: subscription_params[:stripeBillingAddressZip],
        billing_address_state: subscription_params[:stripeBillingAddressState],
        billing_address_city: subscription_params[:stripeBillingAddressCity],
        billing_address_country: subscription_params[:stripeBillingAddressCountry],
        subscription: @subscription.as_json
      }
      @account.customer_id = @customer.id
    end

    def create_subscription
      @subscription = Stripe::Subscription.create(
        customer: @customer.id,
        items: [
          {
            plan: ENV.fetch('XYZ_BASE_PLAN_ID')
          },
          {
            plan: ENV.fetch('XYZ_PAGE_PLAN_ID')
          },
          {
            plan: ENV.fetch('XYZ_DATA_PLAN_ID')
          }
        ]
      )
    end

    def subscription_params
      params.permit([
                      :stripeToken,
                      :stripeBillingName,
                      :stripeBillingAddressLine1,
                      :stripeBillingAddressLine2,
                      :stripeBillingAddressZip,
                      :stripeBillingAddressState,
                      :stripeBillingAddressCity,
                      :stripeBillingAddressCountry,
                    ])
    end

  end
end
