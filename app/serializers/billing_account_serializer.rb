# frozen_string_literal: true

# JSON serializer for BillingAccount objects
class BillingAccountSerializer < ApplicationSerializer
  attributes :customer_id, :metadata
end
