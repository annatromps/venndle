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

ActiveRecord::Schema[8.1].define(version: 2026_05_19_115838) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "attempts", force: :cascade do |t|
    t.boolean "correct", default: false
    t.datetime "created_at", null: false
    t.string "guess"
    t.string "label"
    t.bigint "puzzle_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["puzzle_id"], name: "index_attempts_on_puzzle_id"
    t.index ["user_id"], name: "index_attempts_on_user_id"
  end

  create_table "game_sessions", force: :cascade do |t|
    t.integer "attempts_a", default: 0
    t.integer "attempts_b", default: 0
    t.integer "attempts_c", default: 0
    t.boolean "completed", default: false
    t.datetime "created_at", null: false
    t.bigint "puzzle_id", null: false
    t.boolean "solved_a", default: false
    t.boolean "solved_b", default: false
    t.boolean "solved_c", default: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["puzzle_id"], name: "index_game_sessions_on_puzzle_id"
    t.index ["user_id"], name: "index_game_sessions_on_user_id"
  end

  create_table "puzzles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "label_a"
    t.string "label_b"
    t.string "label_c"
    t.boolean "published", default: false
    t.string "puzzle_type"
    t.date "scheduled_date"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "words_a", default: [], array: true
    t.string "words_ab", default: [], array: true
    t.string "words_abc", default: [], array: true
    t.string "words_ac", default: [], array: true
    t.string "words_b", default: [], array: true
    t.string "words_bc", default: [], array: true
    t.string "words_c", default: [], array: true
    t.index ["user_id"], name: "index_puzzles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "attempts", "puzzles"
  add_foreign_key "attempts", "users"
  add_foreign_key "game_sessions", "puzzles"
  add_foreign_key "game_sessions", "users"
  add_foreign_key "puzzles", "users"
end
