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

ActiveRecord::Schema[8.1].define(version: 2026_04_21_071743) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "competition_activities", force: :cascade do |t|
    t.jsonb "activity_dates_strings"
    t.bigint "competition_user_id"
    t.datetime "created_at", null: false
    t.string "display_name"
    t.float "distance_meters"
    t.float "elevation_meters"
    t.boolean "included_in_competition", default: false, null: false
    t.integer "moving_seconds"
    t.jsonb "override_activity_dates_strings"
    t.datetime "start_at"
    t.jsonb "strava_data"
    t.string "strava_id"
    t.string "timezone"
    t.datetime "updated_at", null: false
    t.index ["competition_user_id"], name: "index_competition_activities_on_competition_user_id"
  end

  create_table "competition_users", force: :cascade do |t|
    t.bigint "competition_id"
    t.datetime "created_at", null: false
    t.text "display_name"
    t.jsonb "included_activity_types"
    t.boolean "included_in_competition", default: false, null: false
    t.decimal "score"
    t.jsonb "score_data"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["competition_id"], name: "index_competition_users_on_competition_id"
    t.index ["user_id"], name: "index_competition_users_on_user_id"
  end

  create_table "competitions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "current"
    t.string "display_name"
    t.date "end_date"
    t.integer "kind", default: 0, null: false
    t.string "legacy_url"
    t.string "slug"
    t.date "start_date"
    t.datetime "updated_at", null: false
  end

  create_table "strava_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "error_response"
    t.integer "kind"
    t.jsonb "parameters"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_strava_requests_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "display_name"
    t.string "encrypted_password", default: "", null: false
    t.text "image_url"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at"
    t.integer "role", default: 0
    t.integer "sign_in_count", default: 0, null: false
    t.jsonb "strava_auth"
    t.string "strava_id"
    t.jsonb "strava_info"
    t.string "strava_username"
    t.integer "theme", default: 0
    t.integer "unit", default: 0, null: false
    t.datetime "updated_at", null: false
  end
end
