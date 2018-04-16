class BillingDataQuantifierJob < BillingQuantifierJob

  def perform(component_id)
    component = Component.find(component_id)
    user = get_user_from_component(component)
    if user && component && component_has_uploaded_media?(component)
      usage = get_component_data_usage(component)
      plan = get_data_plan(user)
      Stripe::UsageRecord.create(
        quantity: usage,
        timestamp: Time.now.to_i,
        subscription_item: plan.id,
        action: 'increment'
      ) if plan
    end
  end
end