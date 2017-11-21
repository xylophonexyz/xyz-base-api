# frozen_string_literal: true

#
# A general Comment model that can be associated to any class
#
class Comment < ApplicationRecord
  include VoteHelper

  acts_as_tree

  belongs_to :commentable, polymorphic: true
  belongs_to :user
  has_many :votes, as: :votable

  after_create :upvote

  validates_presence_of :body, :user_id, :commentable

  def add_reply(comment)
    raise 'Comment is not valid' unless should_add_reply? comment
    children << comment
  end

  def reply_to(parent)
    raise 'Parent is not a comment' unless should_reply_to_parent? parent
    parent.add_reply(self)
  end

  def destroy
    self.disabled = true
    save
  end

  private

  def should_add_reply?(comment)
    comment&.is_a?(Comment) && comment.valid?
  end

  def should_reply_to_parent?(parent)
    parent&.is_a?(Comment)
  end
end
