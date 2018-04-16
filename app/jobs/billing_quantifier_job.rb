class BillingQuantifierJob < ApplicationJob
  require 'stripe'

  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    if user&.billing_account
      customer = Stripe::Customer.retrieve(user.billing_account.customer_id)
      # there should only be one subscription
      subscription = customer.subscriptions.data.first
      subscription_items = subscription.items.data
      # page plan and data plan have metered usage, we want to update the quantity to reflect usage
      page_plan = subscription_items.select { |item| item.plan.id == ENV.fetch('XYZ_PAGE_PLAN_ID') }.first
      data_plan = subscription_items.select { |item| item.plan.id == ENV.fetch('XYZ_DATA_PLAN_ID') }.first
      update_page_usage(user, page_plan) if page_plan
      update_data_usage(user, data_plan) if data_plan
    end
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
        quantity += component.media['transcoding']['bytes_usage'] / 1024 ** 3
      end
    end
    Stripe::UsageRecord.create(
      quantity: quantity,
      timestamp: Time.now.to_i,
      subscription_item: plan.id,
      action: 'set'
    )
  end

  def component_has_uploaded_media?(component)
    component.media && !component.media_processing &&
      (component.is_a?(ImageComponent) || component.is_a?(AudioComponent) ||
        component.is_a?(MediaComponent) || component.is_a?(VideoComponent)) &&
      component.media['transcoding']
  end
end
