# frozen_string_literal: true

# JSON serializer for Page objects that exclude some associations to speed up responses
class PagePreviewSerializer < ApplicationSerializer
  include VoteHelper

  attributes :id, :title, :description, :created_at, :updated_at, :published, :cover, :guessed_title,
             :session, :rating, :comment_count, :views, :nods, :metadata

  belongs_to :user
  belongs_to :composition

  def views
    object.views.count
  end

  def nods
    object.nods.count
  end

  def comment_count
    object.comments.count
  end

  def session
    {
      vote: get_vote_value(object.votes.by_user(scope).first),
      nod: object.nods.by_user(scope).first
    }
  end

  def rating
    get_rating(object)
  end

  def guessed_title
    object.metadata&.dig(:guessed_title)
  end

  def cover
    object.metadata&.dig(:cover)
  end
end
