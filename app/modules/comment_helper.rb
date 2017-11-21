# frozen_string_literal: true

# Helper for Comments related logic
module CommentHelper
  def root_comments
    comments.where(parent_id: nil).order('created_at desc')
  end
end
