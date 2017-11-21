# frozen_string_literal: true

#
# A representation of a published work. Made up of rich and diverse collections of media
# through ComponentCollection objects.
#
# @user_id: the user who owns this page
# @composition_id: the Composition this page is a part of, if any
# @title: title used for publishing purposes
# @description: description used for publishing purposes
# @published: boolean value that signifies whether this Page is a draft or should be published
#
class Page < ApplicationRecord
  include VoteHelper
  include CommentHelper

  serialize :metadata

  belongs_to :user
  belongs_to :composition
  has_many :component_collections, as: :collectible, dependent: :destroy
  has_many :comments, as: :commentable
  has_many :votes, as: :votable
  has_many :nods, as: :noddable
  has_many :views, as: :viewable
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings
  alias_attribute :components, :component_collections

  validates_presence_of :user

  def self.search(query)
    user_query = joins(:user).where('username like ?', "%#{query}%").where(published: true)
    page_query = where('title like ?', "%#{query}%")
                 .where(published: true)
                 .includes(:views, :tags, nods: [:user], votes: [:user], component_collections: [:components])
    user_query + page_query
  end
end
