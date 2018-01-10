# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180110025740) do

  create_table "comment_hierarchies", id: false, force: :cascade do |t|
    t.integer "ancestor_id", null: false
    t.integer "descendant_id", null: false
    t.integer "generations", null: false
    t.index ["ancestor_id", "descendant_id", "generations"], name: "comment_anc_desc_idx", unique: true
    t.index ["descendant_id"], name: "comment_desc_idx"
  end

  create_table "comments", force: :cascade do |t|
    t.string "body", default: ""
    t.integer "parent_id"
    t.integer "commentable_id"
    t.string "commentable_type"
    t.integer "user_id"
    t.boolean "disabled", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commentable_id"], name: "index_comments_on_commentable_id"
    t.index ["commentable_type"], name: "index_comments_on_commentable_type"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "component_collections", force: :cascade do |t|
    t.integer "collectible_id"
    t.string "collectible_type"
    t.integer "index", default: 0
    t.string "type"
    t.text "metadata", limit: 4194303
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collectible_id"], name: "index_component_collections_on_collectible_id"
    t.index ["collectible_type"], name: "index_component_collections_on_collectible_type"
  end

  create_table "components", force: :cascade do |t|
    t.integer "component_collection_id"
    t.text "media", limit: 4194303
    t.boolean "media_processing"
    t.string "type"
    t.integer "index", default: 0
    t.text "metadata", limit: 4194303
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["component_collection_id"], name: "index_components_on_component_collection_id"
  end

  create_table "compositions", force: :cascade do |t|
    t.integer "user_id"
    t.integer "parent_id"
    t.string "title"
    t.datetime "published_on"
    t.text "metadata", limit: 4194303
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_compositions_on_parent_id"
    t.index ["user_id"], name: "index_compositions_on_user_id"
  end

  create_table "nods", force: :cascade do |t|
    t.integer "user_id"
    t.integer "noddable_id"
    t.string "noddable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["noddable_id", "noddable_type"], name: "index_nods_on_noddable_id_and_noddable_type"
    t.index ["user_id"], name: "index_nods_on_user_id"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer "resource_owner_id", null: false
    t.integer "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer "resource_owner_id"
    t.integer "application_id"
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "pages", force: :cascade do |t|
    t.integer "user_id"
    t.integer "composition_id"
    t.string "title"
    t.text "description"
    t.boolean "published", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "metadata", limit: 4194303
    t.index ["composition_id"], name: "index_pages_on_composition_id"
    t.index ["user_id"], name: "index_pages_on_user_id"
  end

  create_table "relationships", force: :cascade do |t|
    t.integer "follower_id"
    t.integer "followed_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["followed_id"], name: "index_relationships_on_followed_id"
    t.index ["follower_id", "followed_id"], name: "index_relationships_on_follower_id_and_followed_id", unique: true
    t.index ["follower_id"], name: "index_relationships_on_follower_id"
  end

  create_table "taggings", force: :cascade do |t|
    t.integer "tag_id"
    t.integer "taggable_id"
    t.string "taggable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type"], name: "index_taggings_on_taggable_id_and_taggable_type"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "username", default: "", null: false
    t.text "bio", limit: 4294967295
    t.string "first_name", default: "", null: false
    t.string "last_name", default: "", null: false
    t.text "avatar", limit: 4294967295
    t.boolean "avatar_processing"
    t.text "metadata", limit: 4194303
    t.string "type"
    t.boolean "onboarded", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username"
  end

  create_table "views", force: :cascade do |t|
    t.integer "viewable_id"
    t.string "viewable_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_views_on_user_id"
    t.index ["viewable_id", "viewable_type"], name: "index_views_on_viewable_id_and_viewable_type"
  end

  create_table "votes", force: :cascade do |t|
    t.integer "votable_id"
    t.string "votable_type"
    t.integer "user_id"
    t.boolean "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_votes_on_user_id"
    t.index ["votable_id"], name: "index_votes_on_votable_id"
    t.index ["votable_type"], name: "index_votes_on_votable_type"
  end

end
