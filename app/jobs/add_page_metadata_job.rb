class AddPageMetadataJob < ApplicationJob
  include PageHelper

  queue_as :default

  def perform(page_id)
    page = Page.find(page_id)
    page.metadata ||= {}
    page.metadata[:guessed_title] = guess_title(page)
    page.metadata[:cover] = cover(page)
    page.save
  end
end
