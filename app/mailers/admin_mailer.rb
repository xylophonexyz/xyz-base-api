# frozen_string_literal: true

# Mailer for sending generic emails from provided tempalates
class AdminMailer < ApplicationMailer
  def send_email(mailer_opts)
    instantiate_mailer
    @message.add_recipient(:to, mailer_opts[:address])
    @message.add_recipient(:from, "#{mailer_opts[:client_app]} <mailgun@#{ENV['MAILGUN_DOMAIN']}>")
    @message.subject(mailer_opts[:subject])
    @message.body_html(mailer_opts[:template])

    @mailgun.send_message ENV['MAILGUN_DOMAIN'], @message
  end
end
