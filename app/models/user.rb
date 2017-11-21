# frozen_string_literal: true

# Main user model for the application
class User < ApplicationRecord
  serialize :metadata

  has_many :compositions, dependent: :destroy
  has_many :pages, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :nods, dependent: :destroy
  has_many :active_relationships, class_name: 'Relationship', foreign_key: 'follower_id', dependent: :destroy
  has_many :passive_relationships, class_name: 'Relationship', foreign_key: 'followed_id', dependent: :destroy
  has_many :following, through: :active_relationships, source: :followed
  has_many :followers, through: :passive_relationships, source: :follower

  validates :email, presence: true, uniqueness: true
  validates :username,
            length: { maximum: 32 },
            format: { with: /\A[a-zA-Z0-9_-]+\Z/ },
            uniqueness: { case_sensitive: false },
            allow_blank: true,
            allow_nil: true

  def self.search(query)
    where('first_name LIKE ? or last_name LIKE ? or username LIKE ? or bio LIKE ?',
          "%#{query}%",
          "%#{query}%",
          "%#{query}%",
          "%#{query}%")
  end

  def follow(other_user)
    active_relationships.create(followed_id: other_user.id)
  end

  def following?(other_user)
    following.include?(other_user)
  end

  def password_required?
    false
  end

  def unfollow(other_user)
    active_relationships.find_by(followed_id: other_user.id).destroy
  end
end
