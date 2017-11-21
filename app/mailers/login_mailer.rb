# frozen_string_literal: true

# Mailer for sending login emails to users
class LoginMailer < ApplicationMailer
  def send_login_email(mailer_opts)
    @address = mailer_opts[:user]&.email
    @redirect_uri = mailer_opts[:redirect_uri]
    @client_app = mailer_opts[:client_app]
    @support_address = mailer_opts[:support_address] || 'support@xylophonexyz.com'
    instantiate_mailer
    send_message
  end

  def send_message
    @message.add_recipient(:to, @address)
    @message.add_recipient(:from, "#{@client_app} <mailgun@#{ENV['MAILGUN_DOMAIN']}>")
    @message.subject("Sign In To #{@client_app}")
    @message.body_html(render_to_string(template: 'login_mailer/new_login').to_str)

    @mailgun.send_message ENV['MAILGUN_DOMAIN'], @message
  end
end
