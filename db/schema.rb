# encoding: UTF-8
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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130428085308) do

  create_table "active_admin_comments", :force => true do |t|
    t.string   "resource_id",   :null => false
    t.string   "resource_type", :null => false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], :name => "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], :name => "index_admin_notes_on_resource_type_and_resource_id"

  create_table "classifier_text_class_feature_properties", :force => true do |t|
    t.integer  "classifier_id"
    t.integer  "text_class_feature_id"
    t.integer  "feature_count"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  add_index "classifier_text_class_feature_properties", ["classifier_id", "text_class_feature_id"], :name => "classifier_tcf_prop_ind"

  create_table "classifiers", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.hstore   "parameters"
  end

  create_table "classifiers_feeds", :force => true do |t|
    t.integer "classifier_id"
    t.integer "feed_id"
  end

  add_index "classifiers_feeds", ["classifier_id", "feed_id"], :name => "index_classifiers_feeds_on_classifier_id_and_feed_id"

  create_table "docs_counts", :force => true do |t|
    t.integer "classifier_id"
    t.integer "text_class_id"
    t.integer "docs_count",    :default => 0
  end

  add_index "docs_counts", ["classifier_id"], :name => "index_docs_counts_on_classifier_id"
  add_index "docs_counts", ["text_class_id"], :name => "index_docs_counts_on_text_class_id"

  create_table "features", :force => true do |t|
    t.string   "token"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "feed_classified_infos", :force => true do |t|
    t.integer  "feed_id"
    t.integer  "classifier_id"
    t.integer  "text_class_id"
    t.boolean  "to_train"
    t.float    "score"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "feed_classified_infos", ["feed_id", "classifier_id"], :name => "index_feed_classified_infos_on_feed_id_and_classifier_id"
  add_index "feed_classified_infos", ["feed_id"], :name => "index_feed_classified_infos_on_feed_id"

  create_table "feed_sources", :force => true do |t|
    t.integer  "text_class_id"
    t.string   "url"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "feed_sources", ["text_class_id"], :name => "index_feed_sources_on_text_class_id"

  create_table "feedbacks_feedbacks", :force => true do |t|
    t.string   "topic"
    t.text     "text"
    t.string   "email"
    t.string   "url"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "feeds", :force => true do |t|
    t.string   "title"
    t.string   "url"
    t.text     "summary"
    t.datetime "published_at"
    t.integer  "text_class_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "rb7_news", :id => false, :force => true do |t|
    t.integer "id",                        :null => false
    t.integer "nid"
    t.string  "title"
    t.string  "annotation", :limit => 500
    t.text    "text"
    t.string  "source"
    t.integer "created"
    t.integer "changed"
    t.integer "tid"
  end

  add_index "rb7_news", ["nid"], :name => "uniq_nid", :unique => true

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "roles", ["name", "resource_type", "resource_id"], :name => "index_roles_on_name_and_resource_type_and_resource_id"
  add_index "roles", ["name"], :name => "index_roles_on_name"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       :limit => 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "text_class_features", :force => true do |t|
    t.integer "text_class_id"
    t.integer "feature_id"
    t.integer "feature_count"
  end

  add_index "text_class_features", ["feature_id", "text_class_id"], :name => "index_text_class_features_on_feature_id_and_text_class_id"
  add_index "text_class_features", ["text_class_id", "feature_id"], :name => "index_text_class_features_on_text_class_id_and_feature_id"

  create_table "text_classes", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.string   "eng_name"
    t.string   "prepositional_name"
  end

  create_table "text_classes_vocabulary_entries", :force => true do |t|
    t.integer "text_class_id"
    t.integer "vocabulary_entry_id"
  end

  add_index "text_classes_vocabulary_entries", ["text_class_id", "vocabulary_entry_id"], :name => "voc_entry_tc_index"

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "name"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "users_roles", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], :name => "index_users_roles_on_user_id_and_role_id"

  create_table "vocabulary_entries", :force => true do |t|
    t.string   "token"
    t.string   "regexp_rule"
    t.integer  "state"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.boolean  "truly_city",  :default => false
  end

  add_index "vocabulary_entries", ["state", "regexp_rule"], :name => "index_vocabulary_entries_on_state_and_regexp_rule"
  add_index "vocabulary_entries", ["state", "token"], :name => "index_vocabulary_entries_on_state_and_token"
  add_index "vocabulary_entries", ["token"], :name => "index_vocabulary_entries_on_token"

end
