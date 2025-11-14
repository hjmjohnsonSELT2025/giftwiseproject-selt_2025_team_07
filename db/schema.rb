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

ActiveRecord::Schema[7.1].define(version: 2025_11_14_073238) do
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
    t.integer "age"
    t.string "occupation"
    t.text "hobbies"
    t.text "likes"
    t.text "dislikes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "event_recipients", "events"
  add_foreign_key "event_recipients", "recipients"
  add_foreign_key "event_recipients", "users"
  add_foreign_key "events", "users"
  add_foreign_key "recipients", "users"
end
