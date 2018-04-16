class BillingDataQuantifierJob < BillingQuantifierJob

  def perform(component_id)
    component = Component.find(component_id)
    user = get_user_from_component(component)
    if user && component && component_has_uploaded_media?(component)
      usage = component_data_usage(component)
      plan = customer_data_plan(user)
      timestamp = usage_period_timestamp(user)
      Stripe::UsageRecord.create(
        quantity: usage,
        timestamp: timestamp,
        subscription_item: plan.id,
        action: 'increment'
      ) if plan
    end
  end
end