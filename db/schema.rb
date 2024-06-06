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

ActiveRecord::Schema[7.1].define(version: 2024_06_06_062332) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "competition_activities", force: :cascade do |t|
    t.bigint "competition_user_id"
    t.string "display_name"
    t.float "distance_meters"
    t.integer "moving_seconds"
    t.float "elevation_meters"
    t.string "timezone"
    t.datetime "start_at"
    t.jsonb "activity_dates_strings"
    t.jsonb "override_activity_dates_strings"
    t.jsonb "strava_data"
    t.string "strava_id"
    t.boolean "included_in_competition", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "included_distance_meters"
    t.index ["competition_user_id"], name: "index_competition_activities_on_competition_user_id"
  end

  create_table "competition_users", force: :cascade do |t|
    t.bigint "competition_id"
    t.bigint "user_id"
    t.boolean "included_in_competition", default: false, null: false
    t.jsonb "score_data"
    t.jsonb "included_activity_types"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "score"
    t.text "display_name"
    t.index ["competition_id"], name: "index_competition_users_on_competition_id"
    t.index ["user_id"], name: "index_competition_users_on_user_id"
  end

  create_table "competitions", force: :cascade do |t|
    t.string "display_name"
    t.string "slug"
    t.date "end_date"
    t.date "start_date"
    t.boolean "current"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "strava_requests", force: :cascade do |t|
    t.bigint "user_id"
    t.jsonb "error_response"
    t.jsonb "parameters"
    t.integer "status"
    t.integer "kind"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_strava_requests_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "role", default: 0
    t.string "strava_username"
    t.string "strava_id"
    t.string "display_name"
    t.text "image_url"
    t.jsonb "strava_info"
    t.jsonb "strava_auth"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
