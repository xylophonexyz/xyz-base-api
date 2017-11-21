# frozen_string_literal: true

# JSON serializer for Comment objects
class CommentSerializer < ApplicationSerializer
  include VoteHelper

  attributes :id, :parent, :children, :body, :disabled, :commentable_id, :commentable_type
  attributes :session

  belongs_to :user

  def children
    object.children.map do |child|
      CommentSerializer.new(child, scope: scope, root: false, event: object)
    end
  end

  def body
    if object.disabled
      ''
    else
      object.body
    end
  end

  def session
    { vote: get_vote_value(object.votes.by_user(scope).first) }
  end
end
