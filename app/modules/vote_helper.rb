# frozen_string_literal: true

# Helper methods for dealing with Vote and Votable objects
module VoteHelper
  def upvotes
    votes.where(value: true)
  end

  def downvotes
    votes.where(value: false)
  end

  def rating
    get_rating(self)
  end

  private

  def upvote
    vote = Vote.new(value: true)
    vote.user = user
    votes.push(vote)
    save
  end

  def get_vote_value(vote)
    vote ? vote.value : nil
  end

  def get_rating(resource)
    score = resource.upvotes.count - resource.downvotes.count
    (base_score(score) + (sign(score) * elapsed_time(resource)) / 4500 * 10).round(4)
  end

  def base_score(score)
    Math.log([score.abs, 1].max, 10)
  end

  def elapsed_time(resource)
    resource.created_at.to_i - Time.new(1970, 1, 1).to_i
  end

  def sign(score)
    if score.positive?
      1
    elsif score.negative?
      -1
    else
      0
    end
  end
end
