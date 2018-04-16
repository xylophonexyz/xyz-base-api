class BillingQuantifierJob < ApplicationJob
  require 'stripe'

  include ComponentsHelper

  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    if user&.billing_account
      page_plan = get_page_plan(user)
      data_plan = get_data_plan(user)
      update_page_usage(user, page_plan) if page_plan
      update_data_usage(user, data_plan) if data_plan
    end
  end

  def get_customer(customer_id)
    Stripe::Customer.retrieve(customer_id)
  end

  def get_subscription_items(user)
    customer = get_customer(user.billing_account.customer_id)
    # there should only be one subscription
    subscription = customer.subscriptions.data.first
    subscription.items.data
  end

  def get_data_plan(user)
    subscription_items = get_subscription_items(user)
    subscription_items.select { |item| item.plan.id == ENV.fetch('XYZ_DATA_PLAN_ID') }.first
  end

  def get_page_plan(user)
    subscription_items = get_subscription_items(user)
    # page plan and data plan have metered usage, we want to update the quantity to reflect usage
    subscription_items.select { |item| item.plan.id == ENV.fetch('XYZ_PAGE_PLAN_ID') }.first
  end

  def update_page_usage(user, plan)
    quantity = user.pages.where(published: true).count
    Stripe::UsageRecord.create(
      quantity: quantity,
      timestamp: Time.now.to_i,
      subscription_item: plan.id,
      action: 'set'
    )
  end

  def update_data_usage(user, plan)
    quantity = 0
    collections_relation = ComponentCollection.where(collectible: user.pages)
    components = Component.where(component_collection: collections_relation)
    components.each do |component|
      if component_has_uploaded_media? component
        quantity += get_component_data_usage(component)
      end
    end
    Stripe::UsageRecord.create(
      quantity: quantity,
      timestamp: Time.now.to_i,
      subscription_item: plan.id,
      action: 'set'
    )
  end

  def get_component_data_usage(component)
    data = get_component_transcoding_data(component)
    data['bytes_usage'] / 1024 ** 3
  end

  def get_user_from_component(component)
    parent = component&.component_collection&.collectible
    return parent if parent.is_a?(User)
    return parent.user if parent
    nil
  end
end
