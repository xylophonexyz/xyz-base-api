# frozen_string_literal: true

# Helper to handle transloadit notification related tasks, such as verification of signatures, and allowing
# transloadit notifications to come through
#
module TransloaditNotificationsHelper
  require 'openssl'

  def verified_signature?
    signature = params[:signature]
    payload = params[:transloadit]
    secret = ENV.fetch('TRANSLOADIT_SECRET')
    calculated_signature = OpenSSL::HMAC.hexdigest('sha1', secret, payload)
    calculated_signature == signature
  end
end
