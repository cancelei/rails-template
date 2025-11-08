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

ActiveRecord::Schema[8.0].define(version: 2025_11_05_125557) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "booking_add_ons", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.bigint "tour_add_on_id", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "price_cents_at_booking", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id", "tour_add_on_id"], name: "index_booking_add_ons_on_booking_id_and_tour_add_on_id", unique: true
    t.index ["booking_id"], name: "index_booking_add_ons_on_booking_id"
    t.index ["tour_add_on_id"], name: "index_booking_add_ons_on_tour_add_on_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.bigint "tour_id", null: false
    t.bigint "user_id", null: false
    t.integer "spots", default: 1
    t.integer "status", default: 0
    t.string "booked_email", null: false
    t.string "booked_name", null: false
    t.string "created_via", default: "guest_booking"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booked_email"], name: "index_bookings_on_booked_email"
    t.index ["tour_id"], name: "index_bookings_on_tour_id"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.bigint "user_id", null: false
    t.bigint "guide_profile_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "likes_count", default: 0
    t.index ["guide_profile_id"], name: "index_comments_on_guide_profile_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "email_logs", force: :cascade do |t|
    t.string "recipient", null: false
    t.string "subject", null: false
    t.string "template", null: false
    t.text "payload_json"
    t.string "provider_message_id"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_email_logs_on_status"
  end

  create_table "guide_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "bio"
    t.string "languages"
    t.float "rating_cached"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_guide_profiles_on_user_id"
  end

  create_table "likes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "comment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["comment_id"], name: "index_likes_on_comment_id"
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.bigint "tour_id", null: false
    t.bigint "user_id", null: false
    t.integer "rating", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_reviews_on_booking_id"
    t.index ["tour_id"], name: "index_reviews_on_tour_id"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "tour_add_ons", force: :cascade do |t|
    t.bigint "tour_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "addon_type", default: 0, null: false
    t.integer "price_cents", null: false
    t.string "currency", default: "BRL", null: false
    t.integer "pricing_type", default: 0, null: false
    t.integer "maximum_quantity"
    t.boolean "active", default: true, null: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_tour_add_ons_on_active"
    t.index ["tour_id", "position"], name: "index_tour_add_ons_on_tour_id_and_position"
    t.index ["tour_id"], name: "index_tour_add_ons_on_tour_id"
  end

  create_table "tours", force: :cascade do |t|
    t.bigint "guide_id", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "status", default: 0
    t.integer "capacity", null: false
    t.integer "price_cents"
    t.string "currency"
    t.string "location_name"
    t.float "latitude"
    t.float "longitude"
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.integer "current_headcount", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tour_type", default: 0, null: false
    t.integer "bookings_count", default: 0, null: false
    t.integer "booking_deadline_hours"
    t.index ["guide_id"], name: "index_tours_on_guide_id"
    t.index ["starts_at"], name: "index_tours_on_starts_at"
    t.index ["status"], name: "index_tours_on_status"
    t.index ["tour_type"], name: "index_tours_on_tour_type"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "session_token"
    t.string "role", default: "tourist"
    t.string "phone"
    t.datetime "last_login_at"
    t.string "name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "weather_snapshots", force: :cascade do |t|
    t.bigint "tour_id", null: false
    t.date "forecast_date", null: false
    t.float "min_temp"
    t.float "max_temp"
    t.string "description"
    t.string "icon"
    t.float "pop"
    t.float "wind_speed"
    t.text "alerts_json"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tour_id", "forecast_date"], name: "index_weather_snapshots_on_tour_id_and_forecast_date", unique: true
    t.index ["tour_id"], name: "index_weather_snapshots_on_tour_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "booking_add_ons", "bookings"
  add_foreign_key "booking_add_ons", "tour_add_ons"
  add_foreign_key "bookings", "tours"
  add_foreign_key "bookings", "users"
  add_foreign_key "comments", "guide_profiles"
  add_foreign_key "comments", "users"
  add_foreign_key "guide_profiles", "users"
  add_foreign_key "likes", "comments"
  add_foreign_key "likes", "users"
  add_foreign_key "reviews", "bookings"
  add_foreign_key "reviews", "tours"
  add_foreign_key "reviews", "users"
  add_foreign_key "tour_add_ons", "tours"
  add_foreign_key "tours", "users", column: "guide_id", validate: false
  add_foreign_key "weather_snapshots", "tours"
end
