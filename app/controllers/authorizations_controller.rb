# frozen_string_literal: true

# Override functionality from Doorkeeper::AuthorizationsController
class AuthorizationsController < Doorkeeper::AuthorizationsController
  include SessionHelper

  def create
    if current_resource_owner && pre_auth.authorizable?
      if custom_template_provided?
        send_custom_email current_resource_owner, authorization.authorize
      else
        send_login_email_for current_resource_owner, authorization.authorize
      end
      head :ok
    else
      head :unauthorized
    end
  end

  private

  def send_login_email_for(user, auth)
    mailer_opts = { user: user, redirect_uri: auth.redirect_uri, client_app: client_app&.name }
    LoginMailer.send_login_email(mailer_opts).deliver_later
  end

  def send_custom_email(user, auth)
    address = user.email
    subject = params[:subject]
    content = params[:template].gsub(/\{\{redirect_uri\}\}/, auth.redirect_uri)
    mailer_opts = { address: address, subject: subject, content: content, client_app: client_app&.name }
    AdminMailer.send_email(mailer_opts).deliver_later
  end

  def custom_template_provided?
    params.key?(:template)
  end
end
