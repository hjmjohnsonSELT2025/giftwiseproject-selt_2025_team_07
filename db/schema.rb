# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_11_19_131427) do
  create_table "ai_gift_suggestions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "event_id", null: false
    t.integer "recipient_id", null: false
    t.integer "event_recipient_id", null: false
    t.string "round_type", default: "initial"
    t.string "title", null: false
    t.text "description"
    t.string "estimated_price"
    t.string "category"
    t.string "special_notes"
    t.string "image_url"
    t.boolean "saved_to_wishlist", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_ai_gift_suggestions_on_event_id"
    t.index ["event_recipient_id", "round_type"], name: "index_ai_gift_suggestions_on_event_recipient_id_and_round_type"
    t.index ["event_recipient_id"], name: "index_ai_gift_suggestions_on_event_recipient_id"
    t.index ["recipient_id"], name: "index_ai_gift_suggestions_on_recipient_id"
    t.index ["user_id"], name: "index_ai_gift_suggestions_on_user_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "resource_type"
    t.integer "resource_id"
    t.string "action"
    t.text "old_value"
    t.text "new_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "authentications", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "provider"
    t.string "uid"
    t.string "email"
    t.string "name"
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_authentications_on_user_id"
  end

  create_table "collaborators", force: :cascade do |t|
    t.integer "event_id", null: false
    t.integer "user_id", null: false
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_collaborators_on_event_id"
    t.index ["user_id"], name: "index_collaborators_on_user_id"
  end

  create_table "event_recipients", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "event_id", null: false
    t.integer "recipient_id", null: false
    t.text "gift_ideas"
    t.decimal "budget_allocated", precision: 10, scale: 2
    t.string "gift_status", default: "planning"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "recipient_id"], name: "index_event_recipients_on_event_id_and_recipient_id", unique: true
    t.index ["event_id"], name: "index_event_recipients_on_event_id"
    t.index ["recipient_id"], name: "index_event_recipients_on_recipient_id"
    t.index ["user_id", "event_id"], name: "index_event_recipients_on_user_id_and_event_id"
    t.index ["user_id", "recipient_id"], name: "index_event_recipients_on_user_id_and_recipient_id"
    t.index ["user_id"], name: "index_event_recipients_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "event_name", null: false
    t.text "description"
    t.date "event_date"
    t.string "location"
    t.decimal "budget", precision: 10, scale: 2
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "event_date"], name: "index_events_on_user_id_and_event_date"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "gift_given_backlogs", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "event_id"
    t.integer "recipient_id", null: false
    t.string "gift_name"
    t.text "description"
    t.decimal "price"
    t.string "category"
    t.string "purchase_link"
    t.date "given_on"
    t.integer "created_from_idea_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "event_name"
    t.index ["event_id"], name: "index_gift_given_backlogs_on_event_id"
    t.index ["recipient_id"], name: "index_gift_given_backlogs_on_recipient_id"
    t.index ["user_id"], name: "index_gift_given_backlogs_on_user_id"
  end

  create_table "gift_ideas", force: :cascade do |t|
    t.integer "event_recipient_id", null: false
    t.string "idea"
    t.text "description"
    t.decimal "price_estimate"
    t.string "link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_recipient_id"], name: "index_gift_ideas_on_event_recipient_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "sender_id"
    t.integer "receiver_id"
    t.text "body"
    t.boolean "read"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "event_id", null: false
    t.text "message"
    t.boolean "read"
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_notifications_on_event_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "password_reset_tokens", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "token"
    t.datetime "expires_at"
    t.boolean "used"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_password_reset_tokens_on_user_id"
  end

  create_table "recipients", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "relationship"
    t.integer "age"
    t.string "gender"
    t.string "occupation"
    t.text "bio"
    t.text "hobbies"
    t.text "likes"
    t.text "favorite_categories"
    t.text "dislikes"
    t.decimal "budget", precision: 10, scale: 2
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_recipients_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "password"
    t.date "date_of_birth"
    t.string "phone_number"
    t.string "gender"
    t.string "occupation"
    t.text "hobbies"
    t.text "likes"
    t.text "dislikes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "wishlists", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "recipient_id", null: false
    t.string "item_name"
    t.text "notes"
    t.integer "priority"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipient_id"], name: "index_wishlists_on_recipient_id"
    t.index ["user_id"], name: "index_wishlists_on_user_id"
  end

  add_foreign_key "ai_gift_suggestions", "event_recipients"
  add_foreign_key "ai_gift_suggestions", "events"
  add_foreign_key "ai_gift_suggestions", "recipients"
  add_foreign_key "ai_gift_suggestions", "users"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "authentications", "users"
  add_foreign_key "collaborators", "events"
  add_foreign_key "collaborators", "users"
  add_foreign_key "event_recipients", "events"
  add_foreign_key "event_recipients", "recipients"
  add_foreign_key "event_recipients", "users"
  add_foreign_key "events", "users"
  add_foreign_key "gift_given_backlogs", "events"
  add_foreign_key "gift_given_backlogs", "recipients"
  add_foreign_key "gift_given_backlogs", "users"
  add_foreign_key "gift_ideas", "event_recipients"
  add_foreign_key "notifications", "events"
  add_foreign_key "notifications", "users"
  add_foreign_key "password_reset_tokens", "users"
  add_foreign_key "recipients", "users"
  add_foreign_key "wishlists", "recipients"
  add_foreign_key "wishlists", "users"
end
