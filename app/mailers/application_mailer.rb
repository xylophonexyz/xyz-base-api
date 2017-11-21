# frozen_string_literal: true

# Base mailer class
class ApplicationMailer < ActionMailer::Base
  require 'mailgun'
  include SessionHelper

  protected

  def instantiate_mailer
    @mailgun = Mailgun::Client.new ENV['MAILGUN_KEY']
    @message = Mailgun::MessageBuilder.new
  end
end
