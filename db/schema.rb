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

ActiveRecord::Schema[7.1].define(version: 2025_07_21_073549) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "account_statement_items", id: :serial, force: :cascade do |t|
    t.integer "account_statement_id", null: false
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.index ["account_statement_id"], name: "index_account_statement_items_on_account_statement_id"
  end

  create_table "account_statements", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.string "public_token", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.jsonb "options", default: {}
    t.string "number", null: false
    t.datetime "deleted_at", precision: nil
    t.string "pdf"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "last_send_at", precision: nil
    t.index ["business_id"], name: "account_statements_business_id_not_deleted_idx", where: "(deleted_at IS NULL)"
    t.index ["business_id"], name: "index_account_statements_on_business_id"
    t.index ["source_id", "source_type"], name: "index_account_statements_on_source_id_and_source_type"
  end

  create_table "account_statements_exports", force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "author_id", null: false
    t.json "options"
    t.text "description"
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_account_statements_exports_on_author_id"
    t.index ["business_id"], name: "index_account_statements_exports_on_business_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "full_name"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "role", default: "", null: false
    t.string "invitation_token"
    t.datetime "invitation_created_at", precision: nil
    t.datetime "invitation_sent_at", precision: nil
    t.datetime "invitation_accepted_at", precision: nil
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.integer "invited_by_id"
    t.integer "invitations_count", default: 0
    t.boolean "active", default: true
    t.boolean "enabled_2fa", default: false
    t.string "mobile"
    t.string "encrypted_verify_code"
    t.datetime "verify_code_expires_at", precision: nil
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_admin_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_admin_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_admin_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_admin_users_on_invited_by_type_and_invited_by_id"
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.bigint "visit_id"
    t.bigint "user_id"
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.bigint "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.string "country"
    t.string "region"
    t.string "city"
    t.float "latitude"
    t.float "longitude"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.string "app_version"
    t.string "os_version"
    t.string "platform"
    t.datetime "started_at"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
  end

  create_table "api_keys", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "token", null: false
    t.boolean "active", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "last_used_at", precision: nil
    t.string "last_used_by_ip"
    t.index ["token"], name: "index_api_keys_on_token", unique: true
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "app_events", id: :serial, force: :cascade do |t|
    t.string "event_type", null: false
    t.jsonb "data"
    t.datetime "created_at", precision: nil, null: false
    t.index ["event_type"], name: "index_app_events_on_event_type"
  end

  create_table "appointment_arrival_times", id: :serial, force: :cascade do |t|
    t.integer "appointment_id"
    t.datetime "arrival_at", precision: nil
    t.text "error"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "sent_at", precision: nil
    t.decimal "travel_distance", precision: 10, scale: 2
    t.index ["appointment_id"], name: "index_appointment_arrival_times_on_appointment_id"
  end

  create_table "appointment_arrivals", force: :cascade do |t|
    t.integer "appointment_id"
    t.datetime "sent_at", precision: nil
    t.datetime "arrival_at", precision: nil
    t.decimal "travel_distance", precision: 10, scale: 2
    t.integer "travel_duration"
    t.text "error"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "travel_start_address"
    t.string "travel_dest_address"
    t.index ["appointment_id"], name: "index_appointment_arrivals_on_appointment_id"
  end

  create_table "appointment_bookings_answers", id: :serial, force: :cascade do |t|
    t.integer "appointment_id", null: false
    t.integer "question_id", null: false
    t.text "question_title", null: false
    t.text "answer"
    t.text "answers"
    t.index ["appointment_id"], name: "index_appointment_bookings_answers_on_appointment_id"
  end

  create_table "appointment_types", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "name"
    t.text "description"
    t.string "item_number"
    t.integer "duration"
    t.integer "price"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "reminder_enable", default: true
    t.integer "default_billable_item_id"
    t.integer "default_treatment_template_id"
    t.integer "availability_type_id"
    t.datetime "deleted_at", precision: nil
    t.boolean "display_on_online_bookings", default: true
    t.string "color"
    t.boolean "is_online_booking_prepayment", default: false
    t.index ["business_id", "availability_type_id"], name: "business_id_availability_type_id"
    t.index ["business_id"], name: "index_appointment_types_on_business_id"
  end

  create_table "appointment_types_billable_items", force: :cascade do |t|
    t.integer "appointment_type_id", null: false
    t.integer "billable_item_id", null: false
    t.index ["appointment_type_id"], name: "index_appointment_types_billable_items_on_appointment_type_id"
    t.index ["billable_item_id"], name: "index_appointment_types_billable_items_on_billable_item_id"
  end

  create_table "appointment_types_practitioners", id: :serial, force: :cascade do |t|
    t.integer "appointment_type_id", null: false
    t.integer "practitioner_id", null: false
    t.index ["practitioner_id"], name: "index_appointment_types_practitioners_on_practitioner_id"
  end

  create_table "appointments", id: :serial, force: :cascade do |t|
    t.integer "practitioner_id", null: false
    t.integer "patient_id", null: false
    t.integer "appointment_type_id", null: false
    t.datetime "start_time", precision: nil
    t.datetime "end_time", precision: nil
    t.text "notes"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "availability_id"
    t.boolean "first_reminder_mail_sent", default: false
    t.string "fid", default: "", null: false
    t.boolean "booked_online", default: false, null: false
    t.datetime "deleted_at", precision: nil
    t.boolean "is_completed", default: false
    t.integer "order", default: 0
    t.datetime "cancelled_at", precision: nil
    t.integer "break_times"
    t.string "public_token"
    t.string "status"
    t.boolean "one_week_reminder_sent", default: false
    t.boolean "is_confirmed", default: false
    t.boolean "is_invoice_required", default: true
    t.integer "patient_case_id"
    t.integer "cancelled_by_id"
    t.index ["appointment_type_id"], name: "index_appointments_on_appointment_type_id"
    t.index ["availability_id"], name: "index_appointments_on_availability_id"
    t.index ["created_at"], name: "index_appointments_on_created_at"
    t.index ["deleted_at"], name: "index_appointments_on_deleted_at"
    t.index ["fid"], name: "index_appointments_on_fid"
    t.index ["patient_case_id"], name: "index_appointments_on_patient_case_id"
    t.index ["patient_id"], name: "index_appointments_on_patient_id"
    t.index ["practitioner_id"], name: "index_appointments_on_practitioner_id"
    t.index ["start_time"], name: "index_appointments_on_start_time"
  end

  create_table "attendance_proof_exports", force: :cascade do |t|
    t.integer "business_id"
    t.integer "author_id"
    t.json "options"
    t.text "description"
    t.string "status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["author_id"], name: "index_attendance_proof_exports_on_author_id"
    t.index ["business_id"], name: "index_attendance_proof_exports_on_business_id"
  end

  create_table "availabilities", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "start_time", precision: nil
    t.datetime "end_time", precision: nil
    t.integer "max_appointment"
    t.integer "service_radius"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "postcode"
    t.string "country"
    t.float "latitude"
    t.float "longitude"
    t.integer "practitioner_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "business_id"
    t.string "group_id"
    t.string "fid", default: "", null: false
    t.boolean "allow_online_bookings", default: true, null: false
    t.integer "recurring_id"
    t.integer "availability_type_id"
    t.integer "appointments_count", default: 0
    t.integer "contact_id"
    t.decimal "driving_distance", precision: 10, scale: 2
    t.text "description"
    t.boolean "order_locked", default: false
    t.integer "order_locked_by"
    t.boolean "hide", default: false
    t.string "routing_status"
    t.integer "availability_subtype_id"
    t.integer "group_appointment_type_id"
    t.jsonb "cached_stats", default: {}
    t.datetime "cached_stats_updated_at"
    t.datetime "deleted_at"
    t.index ["allow_online_bookings"], name: "index_availabilities_on_allow_online_bookings"
    t.index ["business_id", "availability_type_id"], name: "index_business_id_and_availability_type_id"
    t.index ["fid"], name: "index_availabilities_on_fid"
    t.index ["group_id"], name: "index_availabilities_on_group_id"
    t.index ["practitioner_id", "availability_type_id"], name: "index_practitioner_id_and_availability_type_id"
    t.index ["practitioner_id"], name: "index_availabilities_on_practitioner_id"
    t.index ["recurring_id"], name: "index_availabilities_on_recurring_id"
  end

  create_table "availabilities_contacts", id: :serial, force: :cascade do |t|
    t.integer "contact_id"
    t.integer "availability_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["availability_id"], name: "index_availabilities_contacts_on_availability_id"
    t.index ["contact_id"], name: "index_availabilities_contacts_on_contact_id"
  end

  create_table "availability_recurrings", id: :serial, force: :cascade do |t|
    t.integer "practitioner_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "repeat_type", default: "", null: false
    t.integer "repeat_total", default: 1, null: false
    t.integer "repeat_interval", default: 1, null: false
    t.index ["practitioner_id"], name: "index_availability_recurrings_on_practitioner_id"
  end

  create_table "availability_subtypes", force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "name"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_availability_subtypes_on_business_id"
  end

  create_table "billable_item_myob_items", id: :serial, force: :cascade do |t|
    t.integer "billable_item_id"
    t.string "uid"
    t.string "account_id"
    t.string "tax_id"
    t.string "row_version"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["billable_item_id"], name: "index_billable_item_myob_items_on_billable_item_id"
  end

  create_table "billable_items", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "item_number"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "business_id"
    t.boolean "health_insurance_rebate", default: false
    t.integer "tax_id"
    t.string "xero_account_code"
    t.boolean "pricing_for_contact", default: false
    t.boolean "display_on_pricing_page", default: true
    t.datetime "deleted_at", precision: nil
    t.index ["health_insurance_rebate"], name: "index_billable_items_on_health_insurance_rebate"
    t.index ["tax_id"], name: "index_billable_items_on_tax_id"
  end

  create_table "billable_items_contacts", id: :serial, force: :cascade do |t|
    t.integer "billable_item_id"
    t.integer "contact_id"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["billable_item_id"], name: "index_billable_items_contacts_on_billable_item_id"
    t.index ["contact_id"], name: "index_billable_items_contacts_on_contact_id"
  end

  create_table "billable_items_practitioners", id: :serial, force: :cascade do |t|
    t.integer "billable_item_id", null: false
    t.integer "practitioner_id", null: false
    t.index ["billable_item_id"], name: "index_billable_items_practitioners_on_billable_item_id"
    t.index ["practitioner_id"], name: "index_billable_items_practitioners_on_practitioner_id"
  end

  create_table "bookings_questions", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "order", null: false
    t.boolean "required", default: false, null: false
    t.text "title"
    t.string "type", null: false
    t.text "answers"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["business_id"], name: "index_bookings_questions_on_business_id"
  end

  create_table "business_hour_breaks", id: :serial, force: :cascade do |t|
    t.integer "business_hour_id", null: false
    t.string "start_time", null: false
    t.string "end_time", null: false
    t.index ["business_hour_id"], name: "index_business_hour_breaks_on_business_hour_id"
  end

  create_table "business_hours", id: :serial, force: :cascade do |t|
    t.integer "practitioner_id", null: false
    t.integer "day_of_week", null: false
    t.string "start_time", null: false
    t.string "end_time", null: false
    t.boolean "active", default: true, null: false
    t.index ["practitioner_id", "day_of_week"], name: "index_business_hours_on_practitioner_id_and_day_of_week", unique: true
    t.index ["practitioner_id"], name: "index_business_hours_on_practitioner_id"
  end

  create_table "business_invoice_items", id: :serial, force: :cascade do |t|
    t.integer "business_invoice_id"
    t.string "unit_name"
    t.decimal "unit_price", precision: 10, scale: 2, default: "0.0"
    t.integer "quantity"
    t.decimal "amount", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["business_invoice_id"], name: "index_business_invoice_items_on_business_invoice_id"
  end

  create_table "business_invoices", id: :serial, force: :cascade do |t|
    t.integer "business_id"
    t.datetime "issue_date", precision: nil
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0"
    t.decimal "tax", precision: 10, scale: 2, default: "0.0"
    t.decimal "discount", precision: 10, scale: 2, default: "0.0"
    t.decimal "amount", precision: 10, scale: 2, default: "0.0"
    t.string "payment_status"
    t.datetime "date_closed", precision: nil
    t.string "invoice_number"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "notes"
    t.integer "subscription_payment_id"
    t.datetime "last_sent_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.datetime "billing_start_date", precision: nil
    t.datetime "billing_end_date", precision: nil
    t.index ["business_id"], name: "index_business_invoices_on_business_id"
  end

  create_table "business_mailchimp_settings", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "list_name"
    t.string "api_key"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "business_medipass_accounts", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "api_key", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["business_id"], name: "index_business_medipass_accounts_on_business_id", unique: true
  end

  create_table "business_settings", id: :serial, force: :cascade do |t|
    t.string "storage_url"
    t.integer "business_id"
    t.json "google_tag_manager", default: {}
    t.index ["business_id"], name: "index_business_settings_on_business_id"
  end

  create_table "business_stripe_accounts", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "account_id", null: false
    t.string "access_token"
    t.string "refresh_token"
    t.string "publishable_key"
    t.datetime "connected_at", precision: nil
    t.index ["business_id"], name: "index_business_stripe_accounts_on_business_id", unique: true
  end

  create_table "business_tutorials", id: :serial, force: :cascade do |t|
    t.integer "business_id"
    t.text "lessons"
    t.integer "status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["business_id"], name: "index_business_tutorials_on_business_id"
  end

  create_table "businesses", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "mobile"
    t.string "website"
    t.string "fax"
    t.string "email"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "postcode"
    t.string "country"
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "avatar_file_name"
    t.string "avatar_content_type"
    t.bigint "avatar_file_size"
    t.datetime "avatar_updated_at", precision: nil
    t.string "bank_name"
    t.string "bank_branch_number"
    t.string "bank_account_name"
    t.string "bank_account_number"
    t.string "abn"
    t.boolean "is_partner", default: false
    t.boolean "active", default: false
    t.string "currency", default: "aud"
    t.string "policy_url"
    t.boolean "suspended", default: false
    t.string "accounting_email"
    t.index ["active"], name: "index_businesses_on_active"
    t.index ["is_partner"], name: "index_businesses_on_is_partner"
  end

  create_table "businesses_patients", id: :serial, force: :cascade do |t|
    t.integer "patient_id", null: false
    t.integer "business_id", null: false
    t.index ["business_id"], name: "index_businesses_patients_on_business_id"
    t.index ["patient_id"], name: "index_businesses_patients_on_patient_id"
  end

  create_table "businesses_referrals", id: :serial, force: :cascade do |t|
    t.integer "referral_id"
    t.integer "business_id"
    t.index ["business_id"], name: "index_businesses_referrals_on_business_id"
    t.index ["referral_id"], name: "index_businesses_referrals_on_referral_id"
  end

  create_table "calendar_appearance_settings", force: :cascade do |t|
    t.integer "business_id", null: false
    t.text "availability_type_colors"
    t.text "appointment_type_colors"
    t.boolean "is_show_tasks", default: false
    t.index ["business_id"], name: "index_calendar_appearance_settings_on_business_id"
  end

  create_table "case_types", id: :serial, force: :cascade do |t|
    t.string "title"
    t.integer "business_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.text "description"
  end

  create_table "ckeditor_assets", id: :serial, force: :cascade do |t|
    t.string "data_file_name", null: false
    t.string "data_original_file_name"
    t.string "data_content_type"
    t.integer "data_file_size"
    t.string "type", limit: 30
    t.integer "width"
    t.integer "height"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["type"], name: "index_ckeditor_assets_on_type"
  end

  create_table "claiming_auth_groups", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "claiming_auth_group_id", null: false
    t.string "claiming_minor_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["business_id"], name: "index_claiming_auth_groups_on_business_id"
  end

  create_table "claiming_providers", id: :serial, force: :cascade do |t|
    t.integer "auth_group_id", null: false
    t.string "name", null: false
    t.string "provider_number", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "cliniko_records", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.bigint "reference_id", null: false
    t.bigint "internal_id", null: false
    t.string "resource_type", null: false
    t.datetime "last_synced_at", precision: nil, null: false
    t.index ["business_id"], name: "cliniko_records_business_id"
    t.index ["resource_type", "internal_id"], name: "cliniko_records_resource_type_internal_id"
    t.index ["resource_type", "reference_id"], name: "cliniko_records_resource_type_reference_id"
  end

  create_table "communication_attachments", id: :serial, force: :cascade do |t|
    t.integer "communication_template_id", null: false
    t.string "attachment_file_name"
    t.string "attachment_content_type"
    t.bigint "attachment_file_size"
    t.datetime "attachment_updated_at", precision: nil
  end

  create_table "communication_delivery", force: :cascade do |t|
    t.integer "communication_id", null: false
    t.string "recipient"
    t.string "status"
    t.string "error_type"
    t.string "error_message"
    t.string "tracking_id", null: false
    t.datetime "last_tried_at", precision: nil
    t.string "provider_id", null: false
    t.string "provider_resource_id"
    t.string "provider_delivery_status"
    t.json "provider_metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["communication_id"], name: "index_communication_delivery_on_communication_id"
  end

  create_table "communication_templates", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.text "email_subject"
    t.text "content"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name", default: "", null: false
    t.string "template_id", default: "", null: false
    t.boolean "enabled", default: true
    t.json "settings", default: {}
    t.index ["business_id", "template_id"], name: "index_business_id_and_template_id"
    t.index ["business_id"], name: "index_communication_templates_on_business_id"
  end

  create_table "communications", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "practitioner_id"
    t.integer "patient_id"
    t.string "message_type"
    t.string "category"
    t.string "direction"
    t.text "message"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "contact_id"
    t.text "description"
    t.text "content"
    t.integer "source_id"
    t.string "source_type"
    t.string "recipient_type"
    t.integer "recipient_id"
    t.integer "linked_patient_id"
    t.index ["business_id", "practitioner_id"], name: "index_communications_on_business_id_and_practitioner_id"
    t.index ["business_id"], name: "index_communications_on_business_id"
    t.index ["contact_id"], name: "index_communications_on_contact_id"
    t.index ["patient_id"], name: "index_communications_on_patient_id"
    t.index ["practitioner_id", "patient_id"], name: "index_communications_on_practitioner_id_and_patient_id"
    t.index ["practitioner_id"], name: "index_communications_on_practitioner_id"
    t.index ["recipient_id", "recipient_type"], name: "index_communications_on_recipient_id_and_recipient_type"
    t.index ["source_type", "source_id"], name: "index_communications_on_source_type_and_source_id"
  end

  create_table "contact_statements", id: :serial, force: :cascade do |t|
    t.integer "contact_id"
    t.integer "patient_id"
    t.date "start_date"
    t.date "end_date"
    t.string "number"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "public_token"
    t.datetime "deleted_at", precision: nil
    t.string "invoice_status"
    t.index ["contact_id"], name: "index_contact_statements_on_contact_id"
    t.index ["patient_id"], name: "index_contact_statements_on_patient_id"
  end

  create_table "contacts", id: :serial, force: :cascade do |t|
    t.string "business_name"
    t.string "title"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "mobile"
    t.string "fax"
    t.string "email"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "postcode"
    t.string "country"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "business_id"
    t.text "notes"
    t.datetime "deleted_at", precision: nil
    t.float "latitude"
    t.float "longitude"
    t.string "full_name"
    t.jsonb "metadata", default: {}
    t.text "important_notification"
    t.string "company_name"
    t.index ["business_id"], name: "index_contacts_on_business_id"
  end

  create_table "contacts_patients", id: :serial, force: :cascade do |t|
    t.integer "contact_id"
    t.integer "patient_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["contact_id"], name: "index_contacts_patients_on_contact_id"
    t.index ["patient_id"], name: "index_contacts_patients_on_patient_id"
  end

  create_table "conversation_messages", id: :serial, force: :cascade do |t|
    t.integer "conversation_room_id"
    t.text "content"
    t.integer "conversation_message_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["conversation_message_id"], name: "index_conversation_messages_on_conversation_message_id"
    t.index ["conversation_room_id"], name: "index_conversation_messages_on_conversation_room_id"
    t.index ["user_id"], name: "index_conversation_messages_on_user_id"
  end

  create_table "conversation_rooms", id: :serial, force: :cascade do |t|
    t.integer "business_id"
    t.string "url"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "coreplus_records", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "reference_id", null: false
    t.integer "internal_id", null: false
    t.string "resource_type", null: false
    t.datetime "last_synced_at", precision: nil, null: false
    t.index ["business_id"], name: "coreplus_records_business_id"
    t.index ["resource_type", "internal_id"], name: "coreplus_records_resource_type_internal_id"
    t.index ["resource_type", "reference_id"], name: "coreplus_records_resource_type_reference_id"
  end

  create_table "daily_appointments_notifications", id: :serial, force: :cascade do |t|
    t.integer "practitioner_id", null: false
    t.date "date"
    t.datetime "sent_at", precision: nil
    t.index ["practitioner_id"], name: "index_daily_appointments_notifications_on_practitioner_id"
  end

  create_table "deleted_resources", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "resource_id", null: false
    t.string "resource_type", null: false
    t.integer "author_id"
    t.string "author_type"
    t.datetime "deleted_at", precision: nil, null: false
    t.integer "associated_patient_id"
    t.index ["business_id"], name: "index_deleted_resources_on_business_id"
  end

  create_table "email_settings", id: :serial, force: :cascade do |t|
    t.integer "business_id"
    t.boolean "status", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "setting_type"
    t.index ["business_id", "setting_type"], name: "index_email_settings_on_business_id_and_setting_type", unique: true
  end

  create_table "groups", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "category"
    t.integer "business_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["business_id"], name: "index_groups_on_business_id"
  end

  create_table "groups_practitioners", id: :serial, force: :cascade do |t|
    t.integer "group_id"
    t.integer "practitioner_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["group_id"], name: "index_groups_practitioners_on_group_id"
    t.index ["practitioner_id"], name: "index_groups_practitioners_on_practitioner_id"
  end

  create_table "healthkit_records", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "reference_id", null: false
    t.integer "internal_id", null: false
    t.string "resource_type", null: false
    t.datetime "last_synced_at", precision: nil, null: false
    t.index ["business_id", "resource_type", "reference_id"], name: "healthkit_records_business_id_resource_type_reference_id"
    t.index ["business_id"], name: "healthkit_records_business_id"
    t.index ["resource_type", "internal_id"], name: "healthkit_records_resource_type_internal_id"
    t.index ["resource_type", "reference_id"], name: "healthkit_records_resource_type_reference_id"
  end

  create_table "hicaps_items", id: :serial, force: :cascade do |t|
    t.string "item_number", null: false
    t.string "description", null: false
    t.string "abbr"
    t.string "category"
    t.index ["item_number"], name: "index_hicaps_items_on_item_number"
  end

  create_table "hicaps_transactions", id: :serial, force: :cascade do |t|
    t.integer "payment_id", null: false
    t.string "transaction_id", null: false
    t.datetime "requested_at", precision: nil
    t.datetime "approved_at", precision: nil
    t.string "status"
    t.float "amount_benefit"
    t.float "amount_gap"
    t.datetime "created_at", precision: nil
    t.index ["payment_id"], name: "index_hicaps_transactions_on_payment_id"
  end

  create_table "images", id: :serial, force: :cascade do |t|
    t.string "file"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_images_on_user_id"
  end

  create_table "imports", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "date_added", precision: nil
    t.integer "business_id"
    t.string "uploaded_file_name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["business_id"], name: "index_imports_on_business_id"
  end

  create_table "incoming_messages", id: :serial, force: :cascade do |t|
    t.integer "patient_id"
    t.text "message"
    t.datetime "received_at", precision: nil
    t.string "sender"
    t.string "receiver"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "invoice_claims", id: :serial, force: :cascade do |t|
    t.integer "invoice_id", null: false
    t.string "type", null: false
    t.string "status", null: false
    t.string "transaction_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "claim_id"
    t.string "medicare_claim_id"
    t.index ["invoice_id"], name: "index_invoice_claims_on_invoice_id"
    t.index ["type"], name: "index_invoice_claims_on_type"
  end

  create_table "invoice_item_myob_lines", id: :serial, force: :cascade do |t|
    t.integer "invoice_item_id"
    t.integer "row_id"
    t.string "row_version"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["invoice_item_id"], name: "index_invoice_item_myob_lines_on_invoice_item_id"
    t.index ["row_id"], name: "index_invoice_item_myob_lines_on_row_id"
  end

  create_table "invoice_items", id: :serial, force: :cascade do |t|
    t.integer "invoice_id", null: false
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.decimal "unit_price", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "invoiceable_type"
    t.integer "invoiceable_id"
    t.string "unit_name"
    t.string "tax_name"
    t.decimal "tax_rate", precision: 10, scale: 2
    t.decimal "amount", precision: 10, scale: 2, default: "0.0"
    t.string "xero_line_item_id"
    t.string "item_number"
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
    t.index ["invoiceable_id", "invoiceable_type"], name: "index_invoice_items_on_invoiceable_id_and_invoiceable_type"
  end

  create_table "invoice_myob_items", id: :serial, force: :cascade do |t|
    t.integer "invoice_id"
    t.string "uid"
    t.string "row_version"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["invoice_id"], name: "index_invoice_myob_items_on_invoice_id"
  end

  create_table "invoice_settings", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "starting_invoice_number", default: 1, null: false
    t.datetime "updated_at", precision: nil
    t.text "messages"
    t.boolean "enable_services", default: false
    t.boolean "enable_diagnosis", default: false
    t.json "outstanding_reminder", default: {}
    t.index ["business_id"], name: "index_invoice_settings_on_business_id"
  end

  create_table "invoice_shortcuts", id: :serial, force: :cascade do |t|
    t.text "content"
    t.integer "business_id"
    t.string "category"
    t.index ["business_id"], name: "index_invoice_shortcuts_on_business_id"
  end

  create_table "invoices", id: :serial, force: :cascade do |t|
    t.date "issue_date"
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0"
    t.decimal "tax", precision: 10, scale: 2, default: "0.0"
    t.decimal "discount", precision: 10, scale: 2, default: "0.0"
    t.decimal "amount", precision: 10, scale: 2, default: "0.0"
    t.text "notes"
    t.boolean "status"
    t.date "date_closed"
    t.decimal "outstanding", precision: 10, scale: 2, default: "0.0"
    t.integer "appointment_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "patient_id"
    t.integer "practitioner_id"
    t.integer "business_id"
    t.string "invoice_number", default: "", null: false
    t.datetime "deleted_at", precision: nil
    t.text "invoice_to"
    t.integer "patient_case_id"
    t.string "xero_invoice_id"
    t.integer "invoice_to_contact_id"
    t.datetime "last_send_patient_at", precision: nil
    t.string "provider_number"
    t.integer "service_ids", default: [], array: true
    t.integer "diagnose_ids", default: [], array: true
    t.datetime "last_send_at", precision: nil
    t.decimal "amount_ex_tax", precision: 10, scale: 2, default: "0.0", null: false
    t.string "public_token"
    t.datetime "last_send_contact_at", precision: nil
    t.json "outstanding_reminder", default: {}
    t.text "message"
    t.date "service_date"
    t.integer "task_id"
    t.index ["appointment_id"], name: "index_invoices_on_appointment_id"
    t.index ["business_id", "invoice_number"], name: "index_invoices_on_business_id_and_invoice_number"
    t.index ["business_id"], name: "index_invoices_on_business_id", where: "(deleted_at IS NULL)"
    t.index ["deleted_at"], name: "index_invoices_on_deleted_at"
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number"
    t.index ["invoice_to_contact_id"], name: "index_invoices_on_invoice_to_contact_id"
    t.index ["patient_case_id"], name: "index_invoices_on_patient_case_id"
    t.index ["patient_id"], name: "index_invoices_on_patient_id"
    t.index ["practitioner_id"], name: "index_invoices_on_practitioner_id"
    t.index ["task_id"], name: "index_invoices_on_task_id"
  end

  create_table "invoices_pdf_exports", force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "author_id", null: false
    t.json "options"
    t.text "description"
    t.string "status", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["author_id"], name: "index_invoices_pdf_exports_on_author_id"
    t.index ["business_id"], name: "index_invoices_pdf_exports_on_business_id"
  end

  create_table "letter_templates", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "name", null: false
    t.text "content"
    t.string "email_subject"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["business_id"], name: "index_letter_templates_on_business_id"
  end

  create_table "login_activities", force: :cascade do |t|
    t.string "scope"
    t.string "strategy"
    t.string "identity"
    t.boolean "success"
    t.string "failure_reason"
    t.string "user_type"
    t.bigint "user_id"
    t.string "context"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "city"
    t.string "region"
    t.string "country"
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at", precision: nil
    t.index ["identity"], name: "index_login_activities_on_identity"
    t.index ["ip"], name: "index_login_activities_on_ip"
    t.index ["user_type", "user_id"], name: "index_login_activities_on_user_type_and_user_id"
  end

  create_table "medipass_quotes", id: :serial, force: :cascade do |t|
    t.integer "invoice_id", null: false
    t.string "transaction_id", null: false
    t.string "member_id", null: false
    t.decimal "amount_gap", precision: 10, scale: 2, default: "0.0"
    t.decimal "amount_benefit", precision: 10, scale: 2, default: "0.0"
    t.decimal "amount_fee", precision: 10, scale: 2, default: "0.0"
    t.decimal "amount_charged", precision: 10, scale: 2, default: "0.0"
    t.decimal "amount_discount", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["invoice_id"], name: "index_medipass_quotes_on_invoice_id"
  end

  create_table "medipass_transactions", id: :serial, force: :cascade do |t|
    t.integer "invoice_id", null: false
    t.integer "payment_id"
    t.string "transaction_id", null: false
    t.datetime "requested_at", precision: nil
    t.datetime "approved_at", precision: nil
    t.datetime "cancelled_at", precision: nil
    t.string "status", null: false
    t.decimal "amount_benefit", precision: 10, scale: 2, default: "0.0"
    t.decimal "amount_gap", precision: 10, scale: 2, default: "0.0"
    t.string "token", null: false
    t.datetime "created_at", precision: nil
    t.index ["invoice_id"], name: "index_medipass_transactions_on_invoice_id"
    t.index ["payment_id"], name: "index_medipass_transactions_on_payment_id"
  end

  create_table "merge_resources_history", force: :cascade do |t|
    t.integer "author_id", null: false
    t.string "resource_type", null: false
    t.integer "target_resource_id", null: false
    t.string "merged_resource_ids", null: false
    t.text "meta"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_merge_resources_history_on_author_id"
    t.index ["resource_type"], name: "index_merge_resources_history_on_resource_type"
    t.index ["target_resource_id"], name: "index_merge_resources_history_on_target_resource_id"
  end

  create_table "myob_accounts", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "access_token"
    t.string "refresh_token"
    t.datetime "access_token_expires_at", precision: nil
    t.string "company_file_id"
    t.string "default_tax_id"
    t.string "default_freight_id"
    t.string "default_invoice_item_tax_id"
    t.string "default_invoice_item_account_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "company_file_name"
    t.string "default_payment_account_id"
    t.string "default_exempt_tax_id"
    t.index ["business_id"], name: "index_myob_accounts_on_business_id"
  end

  create_table "nookal_records", force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "reference_id", null: false
    t.integer "internal_id", null: false
    t.string "resource_type", null: false
    t.datetime "last_synced_at", precision: nil, null: false
    t.index ["business_id", "resource_type", "reference_id"], name: "nookal_records_business_id_resource_type_reference_id"
    t.index ["business_id"], name: "nookal_records_business_id"
    t.index ["resource_type", "internal_id"], name: "nookal_records_resource_type_internal_id"
    t.index ["resource_type", "reference_id"], name: "nookal_records_resource_type_reference_id"
  end

  create_table "notification_type_settings", force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "notification_type_id", null: false
    t.jsonb "enabled_delivery_methods", default: []
    t.jsonb "template", default: {}
    t.boolean "enabled", default: true
    t.jsonb "config", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_notification_type_settings_on_business_id"
    t.index ["notification_type_id"], name: "index_notification_type_settings_on_notification_type_id"
  end

  create_table "notification_types", id: :string, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.jsonb "available_delivery_methods", default: []
    t.jsonb "default_template", default: {}
    t.jsonb "default_config", default: {}
  end

  create_table "outcome_measure_tests", id: :serial, force: :cascade do |t|
    t.integer "outcome_measure_id", null: false
    t.date "date_performed", null: false
    t.float "result", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["outcome_measure_id"], name: "index_outcome_measure_id"
  end

  create_table "outcome_measure_types", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "outcome_type", null: false
    t.string "unit"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["business_id"], name: "index_outcome_measure_types_on_business_id"
  end

  create_table "outcome_measures", id: :serial, force: :cascade do |t|
    t.integer "patient_id", null: false
    t.integer "outcome_measure_type_id", null: false
    t.integer "practitioner_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "patient_access_settings", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.boolean "enable", default: false
    t.index ["business_id"], name: "index_patient_access_settings_on_business_id", unique: true
  end

  create_table "patient_accesses", id: :serial, force: :cascade do |t|
    t.integer "patient_id", null: false
    t.integer "user_id", null: false
    t.index ["patient_id"], name: "index_patient_accesses_on_patient_id"
    t.index ["user_id"], name: "index_patient_accesses_on_user_id"
  end

  create_table "patient_attachment_exports", force: :cascade do |t|
    t.integer "business_id"
    t.integer "author_id"
    t.json "options"
    t.text "description"
    t.string "status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["author_id"], name: "index_patient_attachment_exports_on_author_id"
    t.index ["business_id"], name: "index_patient_attachment_exports_on_business_id"
  end

  create_table "patient_attachments", id: :serial, force: :cascade do |t|
    t.integer "patient_id", null: false
    t.string "attachment_file_name"
    t.string "attachment_content_type"
    t.bigint "attachment_file_size"
    t.datetime "attachment_updated_at", precision: nil
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "patient_case_id"
    t.index ["patient_case_id"], name: "index_patient_attachments_on_patient_case_id"
    t.index ["patient_id"], name: "index_patient_attachments_on_patient_id"
  end

  create_table "patient_bulk_archive_requests", force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "author_id", null: false
    t.text "description"
    t.json "filters"
    t.integer "archived_patients_count"
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "archived_patient_ids"
    t.index ["business_id"], name: "index_patient_bulk_archive_requests_on_business_id"
  end

  create_table "patient_cases", id: :serial, force: :cascade do |t|
    t.text "notes"
    t.string "status"
    t.integer "practitioner_id"
    t.integer "case_type_id"
    t.integer "patient_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.float "invoice_total"
    t.integer "invoice_number"
    t.datetime "archived_at", precision: nil
    t.date "end_date"
    t.index ["case_type_id"], name: "index_patient_cases_on_case_type_id"
    t.index ["patient_id"], name: "index_patient_cases_on_patient_id"
    t.index ["practitioner_id"], name: "index_patient_cases_on_practitioner_id"
  end

  create_table "patient_contacts", id: :serial, force: :cascade do |t|
    t.integer "patient_id", null: false
    t.integer "contact_id", null: false
    t.string "type"
    t.boolean "primary", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["contact_id"], name: "index_patient_contacts_on_contact_id"
    t.index ["patient_id", "type"], name: "index_patient_contacts_on_patient_id_and_type"
    t.index ["patient_id"], name: "index_patient_contacts_on_patient_id"
  end

  create_table "patient_id_numbers", id: :serial, force: :cascade do |t|
    t.integer "patient_id"
    t.integer "contact_id"
    t.string "id_number"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["contact_id"], name: "index_patient_id_numbers_on_contact_id"
    t.index ["patient_id"], name: "index_patient_id_numbers_on_patient_id"
  end

  create_table "patient_letters", id: :serial, force: :cascade do |t|
    t.integer "patient_id", null: false
    t.integer "letter_template_id"
    t.integer "business_id", null: false
    t.integer "author_id"
    t.string "description"
    t.text "content"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["business_id"], name: "index_patient_letters_on_business_id"
    t.index ["letter_template_id"], name: "index_patient_letters_on_letter_template_id"
    t.index ["patient_id"], name: "index_patient_letters_on_patient_id"
  end

  create_table "patient_letters_exports", force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "author_id", null: false
    t.json "options"
    t.text "description"
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_patient_letters_exports_on_author_id"
    t.index ["business_id"], name: "index_patient_letters_exports_on_business_id"
  end

  create_table "patient_myob_accounts", id: :serial, force: :cascade do |t|
    t.integer "patient_id"
    t.string "uid"
    t.string "row_version"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["patient_id"], name: "index_patient_myob_accounts_on_patient_id"
  end

  create_table "patient_statements", id: :serial, force: :cascade do |t|
    t.integer "patient_id"
    t.date "start_date"
    t.date "end_date"
    t.string "number"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "public_token"
    t.datetime "deleted_at", precision: nil
    t.string "invoice_status"
    t.index ["patient_id"], name: "index_patient_statements_on_patient_id"
  end

  create_table "patient_stripe_customers", id: :serial, force: :cascade do |t|
    t.integer "patient_id", null: false
    t.string "stripe_customer_id", null: false
    t.string "stripe_owner_account_id", null: false
    t.string "card_last4", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["patient_id"], name: "index_patient_stripe_customers_on_patient_id"
  end

  create_table "patients", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "mobile"
    t.string "website"
    t.string "fax"
    t.string "email"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "postcode"
    t.string "country"
    t.float "latitude"
    t.float "longitude"
    t.date "dob"
    t.string "gender"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "timezone", default: "Australia/Brisbane"
    t.boolean "reminder_enable", default: true
    t.datetime "archived_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.string "medipass_member_id"
    t.integer "import_id"
    t.string "xero_contact_id"
    t.string "full_name"
    t.text "general_info"
    t.string "phone_formated"
    t.string "mobile_formated"
    t.text "next_of_kin"
    t.jsonb "medicare_details", default: {}
    t.jsonb "dva_details", default: {}
    t.integer "business_id", default: 0, null: false
    t.boolean "accepted_privacy_policy"
    t.string "nationality"
    t.string "aboriginal_status"
    t.string "spoken_languages"
    t.jsonb "ndis_details", default: {}
    t.jsonb "hcp_details", default: {}
    t.jsonb "hih_details", default: {}
    t.jsonb "hi_details", default: {}
    t.text "important_notification"
    t.jsonb "strc_details", default: {}
    t.string "title"
    t.index ["deleted_at"], name: "index_patients_on_deleted_at"
  end

  create_table "payment_allocations", id: :serial, force: :cascade do |t|
    t.integer "payment_id", null: false
    t.integer "invoice_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["invoice_id"], name: "index_payment_allocations_on_invoice_id"
    t.index ["payment_id"], name: "index_payment_allocations_on_payment_id"
  end

  create_table "payment_myob_items", id: :serial, force: :cascade do |t|
    t.integer "payment_id", null: false
    t.string "uid", null: false
    t.string "row_version", null: false
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "payment_type", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["payment_id"], name: "index_payment_myob_items_on_payment_id"
  end

  create_table "payment_types", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "name", null: false
    t.string "type", null: false
    t.string "myob_account_id"
    t.string "xero_account_id"
    t.index ["business_id", "type"], name: "index_payment_types_on_business_id_and_type", unique: true
    t.index ["business_id"], name: "index_payment_types_on_business_id"
  end

  create_table "payments", id: :serial, force: :cascade do |t|
    t.date "payment_date"
    t.decimal "eftpos", precision: 10, scale: 2, default: "0.0"
    t.decimal "hicaps", precision: 10, scale: 2, default: "0.0"
    t.decimal "cash", precision: 10, scale: 2, default: "0.0"
    t.decimal "medicare", precision: 10, scale: 2, default: "0.0"
    t.decimal "workcover", precision: 10, scale: 2, default: "0.0"
    t.decimal "dva", precision: 10, scale: 2, default: "0.0"
    t.decimal "other", precision: 10, scale: 2, default: "0.0"
    t.decimal "amount", precision: 10, scale: 2, default: "0.0"
    t.integer "invoice_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "patient_id"
    t.string "payment_method"
    t.boolean "payment_method_status"
    t.text "payment_method_status_info"
    t.string "stripe_charge_id"
    t.integer "business_id"
    t.datetime "deleted_at", precision: nil
    t.decimal "stripe_charge_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "direct_deposit", precision: 10, scale: 2, default: "0.0"
    t.decimal "cheque", precision: 10, scale: 2, default: "0.0"
    t.boolean "editable", default: true
    t.index ["business_id"], name: "index_payments_on_business_id", where: "(deleted_at IS NULL)"
    t.index ["deleted_at"], name: "index_payments_on_deleted_at"
    t.index ["invoice_id"], name: "index_payments_on_invoice_id"
    t.index ["patient_id"], name: "index_payments_on_patient_id"
  end

  create_table "physitrack_integrations", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.boolean "enabled", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["business_id"], name: "index_physitrack_integrations_on_business_id", unique: true
  end

  create_table "posts_tags", id: :serial, force: :cascade do |t|
    t.integer "post_id", null: false
    t.integer "tag_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["post_id"], name: "index_posts_tags_on_post_id"
    t.index ["tag_id"], name: "index_posts_tags_on_tag_id"
  end

  create_table "practitioner_business_hours", force: :cascade do |t|
    t.integer "practitioner_id", null: false
    t.integer "day_of_week", null: false
    t.boolean "active", default: true
    t.json "availability"
    t.index ["practitioner_id"], name: "index_practitioner_business_hours_on_practitioner_id"
  end

  create_table "practitioner_documents", id: :serial, force: :cascade do |t|
    t.integer "practitioner_id", null: false
    t.string "type", null: false
    t.string "document", null: false
    t.string "document_original_filename", null: false
    t.date "expiry_date"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["practitioner_id"], name: "index_practitioner_documents_on_practitioner_id"
  end

  create_table "practitioners", id: :serial, force: :cascade do |t|
    t.integer "business_id"
    t.string "first_name"
    t.string "last_name"
    t.string "profession"
    t.string "ahpra"
    t.string "medicare"
    t.string "phone"
    t.string "mobile"
    t.string "website"
    t.string "email"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "postcode"
    t.string "country"
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "color", default: "#3a87ad", null: false
    t.text "summary"
    t.string "education"
    t.text "service_description"
    t.text "availability"
    t.boolean "approved", default: false
    t.string "slug", default: "", null: false
    t.string "driver_license"
    t.string "ahpra_registration"
    t.string "medicare_provider_documentation"
    t.string "police_check"
    t.string "insurance_document"
    t.string "video_url"
    t.string "clinic_name"
    t.string "clinic_website"
    t.string "clinic_phone"
    t.string "clinic_booking_url"
    t.integer "user_id"
    t.boolean "active", default: true, null: false
    t.string "full_name"
    t.string "signature_file_name"
    t.string "signature_content_type"
    t.bigint "signature_file_size"
    t.datetime "signature_updated_at", precision: nil
    t.decimal "rating_score", precision: 10, scale: 2, default: "0.0", null: false
    t.boolean "sms_reminder_enabled", default: true
    t.jsonb "metadata", default: {}
    t.boolean "public_profile", default: true
    t.boolean "allow_online_bookings", default: true
    t.float "local_latitude"
    t.float "local_longitude"
    t.index ["active"], name: "index_practitioners_on_active"
    t.index ["approved", "public_profile", "active"], name: "idx_practitioners_approved_public_profile_active"
    t.index ["approved"], name: "index_practitioners_on_approved"
    t.index ["business_id"], name: "index_practitioners_on_business_id"
    t.index ["slug"], name: "index_practitioners_on_slug"
    t.index ["user_id"], name: "index_practitioners_on_user_id"
  end

  create_table "practitioners_tags", id: :serial, force: :cascade do |t|
    t.integer "practitioner_id", null: false
    t.integer "tag_id", null: false
    t.index ["practitioner_id"], name: "index_practitioners_tags_on_practitioner_id"
    t.index ["tag_id"], name: "index_practitioners_tags_on_tag_id"
  end

  create_table "product_myob_items", id: :serial, force: :cascade do |t|
    t.integer "product_id"
    t.string "uid"
    t.string "account_id"
    t.string "tax_id"
    t.string "row_version"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["product_id"], name: "index_product_myob_items_on_product_id"
  end

  create_table "products", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "name", null: false
    t.string "item_code"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.string "serial_number"
    t.string "supplier_name"
    t.string "supplier_phone"
    t.string "supplier_email"
    t.text "notes"
    t.integer "tax_id"
    t.string "image_file_name"
    t.string "image_content_type"
    t.bigint "image_file_size"
    t.datetime "image_updated_at", precision: nil
    t.string "xero_account_code"
    t.datetime "deleted_at", precision: nil
    t.index ["business_id"], name: "index_products_on_business_id"
  end

  create_table "referral_attachments", id: :serial, force: :cascade do |t|
    t.integer "referral_id"
    t.string "attachment_file_name"
    t.string "attachment_content_type"
    t.bigint "attachment_file_size"
    t.datetime "attachment_updated_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["referral_id"], name: "index_referral_attachments_on_referral_id"
  end

  create_table "referral_enquiry_qualifications", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.string "status"
    t.string "token"
    t.datetime "expires_at", precision: nil
    t.integer "practitioner_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["practitioner_id"], name: "index_referral_enquiry_qualifications_on_practitioner_id"
  end

  create_table "referral_reject_reasons", force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "reason"
    t.datetime "created_at"
    t.index ["business_id"], name: "index_referral_reject_reasons_on_business_id"
  end

  create_table "referrals", id: :serial, force: :cascade do |t|
    t.integer "availability_type_id"
    t.string "profession"
    t.integer "practitioner_id"
    t.integer "patient_id"
    t.integer "business_id"
    t.string "status"
    t.text "patient_attrs"
    t.string "referrer_name"
    t.string "referrer_phone"
    t.string "referrer_email"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "attachment_file_name"
    t.string "attachment_content_type"
    t.bigint "attachment_file_size"
    t.datetime "attachment_updated_at", precision: nil
    t.text "medical_note"
    t.string "type"
    t.string "priority"
    t.date "contact_referrer_date"
    t.date "contact_patient_date"
    t.date "first_appoinment_date"
    t.date "send_treatment_plan_date"
    t.date "receive_referral_date"
    t.string "summary_referral"
    t.string "referrer_business_name"
    t.text "professions"
    t.text "referral_reason"
    t.datetime "archived_at", precision: nil
    t.integer "linked_contact_id"
    t.text "internal_note"
    t.date "send_service_agreement_date"
    t.string "reject_reason"
    t.datetime "approved_at"
    t.datetime "rejected_at"
    t.index ["availability_type_id"], name: "index_referrals_on_availability_type_id"
    t.index ["practitioner_id"], name: "index_referrals_on_practitioner_id"
  end

  create_table "reviews", id: :serial, force: :cascade do |t|
    t.integer "practitioner_id"
    t.integer "patient_id"
    t.integer "rating"
    t.text "comment"
    t.boolean "publish_rating", default: true
    t.boolean "publish_comment", default: true
    t.boolean "approved", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "patient_name", default: "", null: false
    t.integer "source_appointment_id"
    t.index ["patient_id"], name: "index_reviews_on_patient_id"
    t.index ["practitioner_id"], name: "index_reviews_on_practitioner_id"
  end

  create_table "splose_records", force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "reference_id", null: false
    t.integer "internal_id", null: false
    t.string "resource_type", null: false
    t.datetime "last_synced_at", null: false
    t.index ["business_id"], name: "splose_records_business_id"
    t.index ["resource_type", "internal_id"], name: "splose_records_resource_type_internal_id"
    t.index ["resource_type", "reference_id"], name: "splose_records_resource_type_reference_id"
  end

  create_table "stripe_infos", id: :serial, force: :cascade do |t|
    t.string "stripe_customer_id"
    t.integer "patient_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "subscription_billings", id: :serial, force: :cascade do |t|
    t.integer "subscription_id"
    t.integer "appointment_id"
    t.datetime "first_invoice_date", precision: nil
    t.string "billing_type"
    t.decimal "subscription_price_on_date", precision: 10, scale: 2, default: "0.0"
    t.decimal "discount_applied", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "business_invoice_id"
    t.integer "quantity"
    t.string "trigger_type"
    t.text "triggers"
    t.text "description"
    t.index ["appointment_id"], name: "index_subscription_billings_on_appointment_id"
    t.index ["subscription_id"], name: "index_subscription_billings_on_subscription_id"
  end

  create_table "subscription_payments", id: :serial, force: :cascade do |t|
    t.datetime "payment_date", precision: nil
    t.decimal "amount", precision: 10, scale: 2, default: "0.0"
    t.string "stripe_charge_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "business_id"
    t.string "payment_type"
    t.integer "invoice_id"
    t.index ["invoice_id"], name: "index_subscription_payments_on_invoice_id"
  end

  create_table "subscription_plans", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.decimal "appointment_price", precision: 10, scale: 2, default: "0.0"
    t.decimal "sms_price", precision: 10, scale: 2, default: "0.0"
    t.decimal "routes_price", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "subscriptions", id: :serial, force: :cascade do |t|
    t.integer "subscription_plan_id"
    t.integer "business_id"
    t.datetime "trial_start", precision: nil
    t.datetime "trial_end", precision: nil
    t.datetime "billing_start", precision: nil
    t.datetime "billing_end", precision: nil
    t.string "status"
    t.string "stripe_customer_id"
    t.string "card_last4"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "email"
    t.jsonb "admin_settings", default: {}
    t.index ["business_id"], name: "index_subscriptions_on_business_id"
    t.index ["subscription_plan_id"], name: "index_subscriptions_on_subscription_plan_id"
  end

  create_table "task_users", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "task_id"
    t.string "status"
    t.datetime "complete_at"
    t.datetime "updated_at"
    t.integer "completion_duration"
    t.index ["task_id"], name: "index_task_users_on_task_id"
    t.index ["user_id"], name: "index_task_users_on_user_id"
  end

  create_table "tasks", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "priority"
    t.text "description"
    t.date "due_on"
    t.string "status"
    t.integer "business_id"
    t.integer "owner_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "patient_id"
    t.boolean "is_invoice_required", default: true
    t.index ["business_id"], name: "index_tasks_on_business_id"
    t.index ["owner_id"], name: "index_tasks_on_owner_id"
  end

  create_table "taxes", id: :serial, force: :cascade do |t|
    t.string "name"
    t.float "rate"
    t.integer "business_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "xero_tax_type"
    t.string "myob_tax_id"
    t.index ["business_id"], name: "index_taxes_on_business_id"
  end

  create_table "treatment_contents", id: :serial, force: :cascade do |t|
    t.integer "treatment_id", null: false
    t.integer "section_id", null: false
    t.integer "question_id", null: false
    t.text "content"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "sname"
    t.integer "sorder"
    t.string "qname"
    t.integer "qtype"
    t.integer "qorder"
    t.index ["question_id"], name: "index_treatment_contents_on_question_id"
    t.index ["section_id"], name: "index_treatment_contents_on_section_id"
    t.index ["treatment_id"], name: "index_treatment_contents_on_treatment_id"
  end

  create_table "treatment_notes_exports", force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "author_id", null: false
    t.json "options"
    t.text "description"
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_treatment_notes_exports_on_author_id"
    t.index ["business_id"], name: "index_treatment_notes_exports_on_business_id"
  end

  create_table "treatment_shortcuts", id: :serial, force: :cascade do |t|
    t.text "content", null: false
    t.integer "business_id"
    t.index ["business_id"], name: "index_treatment_shortcuts_on_business_id"
  end

  create_table "treatment_template_questions", id: :serial, force: :cascade do |t|
    t.integer "section_id", null: false
    t.string "name"
    t.integer "qtype"
    t.integer "qorder"
    t.text "content"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["section_id"], name: "index_treatment_template_questions_on_section_id"
  end

  create_table "treatment_template_sections", id: :serial, force: :cascade do |t|
    t.integer "template_id", null: false
    t.string "name"
    t.integer "stype"
    t.integer "sorder"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["template_id"], name: "index_treatment_template_sections_on_template_id"
  end

  create_table "treatment_templates", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "name"
    t.string "print_name"
    t.boolean "print_address"
    t.boolean "print_birth"
    t.boolean "print_ref_num"
    t.boolean "print_doctor"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.text "template_sections"
    t.integer "sections_count", default: 0
    t.integer "questions_count", default: 0
    t.index ["business_id"], name: "index_treatment_templates_on_business_id", where: "(deleted_at IS NULL)"
  end

  create_table "treatment_templates_users", id: :serial, force: :cascade do |t|
    t.integer "treatment_template_id", null: false
    t.integer "user_id", null: false
  end

  create_table "treatments", id: :serial, force: :cascade do |t|
    t.integer "appointment_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "patient_id"
    t.integer "practitioner_id"
    t.integer "treatment_template_id"
    t.string "name"
    t.string "print_name"
    t.boolean "print_address", default: false
    t.boolean "print_birth", default: false
    t.boolean "print_ref_num", default: false
    t.boolean "print_doctor", default: false
    t.integer "patient_case_id"
    t.string "status"
    t.text "sections"
    t.integer "author_id"
    t.string "author_name"
    t.index ["appointment_id"], name: "index_treatments_on_appointment_id"
    t.index ["author_id"], name: "index_treatments_on_author_id"
    t.index ["patient_case_id"], name: "index_treatments_on_patient_case_id"
    t.index ["patient_id"], name: "index_treatments_on_patient_id"
    t.index ["treatment_template_id"], name: "index_treatments_on_treatment_template_id"
  end

  create_table "trigger_categories", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "name"
    t.integer "words_count", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["business_id"], name: "index_trigger_categories_on_business_id"
  end

  create_table "trigger_reports", id: :serial, force: :cascade do |t|
    t.string "trigger_source_id", null: false
    t.integer "trigger_source_type", null: false
    t.integer "mentions_count", default: 0, null: false
    t.integer "patients_count", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["trigger_source_id", "trigger_source_type"], name: "idx_trigger_reports_source_id_type"
  end

  create_table "trigger_words", id: :serial, force: :cascade do |t|
    t.integer "category_id", null: false
    t.string "text", null: false
    t.integer "mentions_count"
    t.integer "patients_count"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["category_id"], name: "index_trigger_words_on_category_id"
  end

  create_table "user_google_calendar_sync_history", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "event_id", null: false
    t.integer "appointment_id", null: false
    t.datetime "created_at", precision: nil, null: false
  end

  create_table "user_google_calendar_sync_records", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "calendar_event_id", null: false
    t.string "calendar_id", null: false
    t.integer "sync_object_id", null: false
    t.string "sync_object_type", null: false
    t.datetime "last_sync_at", precision: nil
    t.json "last_sync_state"
    t.datetime "created_at", precision: nil, null: false
    t.index ["calendar_event_id"], name: "index_user_google_calendar_sync_records_on_calendar_event_id"
    t.index ["sync_object_id", "sync_object_type"], name: "idx_google_calendar_sync_object_id_object_type"
    t.index ["user_id"], name: "index_user_google_calendar_sync_records_on_user_id"
  end

  create_table "user_google_calendar_sync_settings", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "calendar_id", null: false
    t.string "access_token"
    t.string "refresh_token"
    t.datetime "access_token_expires_at", precision: nil
    t.datetime "connected_at", precision: nil
    t.string "status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_user_google_calendar_sync_settings_on_user_id"
  end

  create_table "user_preferences", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "key", null: false
    t.string "value_type", default: "string", null: false
    t.text "value"
    t.index ["user_id", "key"], name: "index_user_preferences_on_user_id_and_key", unique: true
    t.index ["user_id"], name: "index_user_preferences_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "business_id"
    t.string "timezone", default: "Australia/Brisbane", null: false
    t.string "invitation_token"
    t.datetime "invitation_created_at", precision: nil
    t.datetime "invitation_sent_at", precision: nil
    t.datetime "invitation_accepted_at", precision: nil
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.integer "invited_by_id"
    t.integer "invitations_count", default: 0
    t.string "role", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "full_name"
    t.boolean "is_practitioner", default: true
    t.string "avatar_file_name"
    t.string "avatar_content_type"
    t.bigint "avatar_file_size"
    t.datetime "avatar_updated_at", precision: nil
    t.boolean "active", default: true
    t.string "google_authenticator_secret"
    t.boolean "enable_google_authenticator", default: false
    t.string "employee_number"
    t.datetime "google_authenticator_secret_created_at"
    t.index ["active"], name: "index_users_on_active"
    t.index ["business_id", "active"], name: "index_users_on_business_id_and_active"
    t.index ["business_id"], name: "index_users_on_business_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by_type_and_invited_by_id"
    t.index ["is_practitioner"], name: "index_users_on_is_practitioner"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type"
    t.string "{:null=>false}"
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.json "object"
    t.json "object_changes"
    t.datetime "created_at", precision: nil
    t.string "ip"
    t.string "user_agent"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "wait_lists", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "patient_id", null: false
    t.integer "practitioner_id"
    t.date "date", null: false
    t.string "profession"
    t.integer "appointment_type_id"
    t.string "repeat_group_uid"
    t.boolean "scheduled", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "notes"
    t.index ["business_id"], name: "index_wait_lists_on_business_id"
    t.index ["patient_id"], name: "index_wait_lists_on_patient_id"
    t.index ["practitioner_id"], name: "index_wait_lists_on_practitioner_id"
  end

  create_table "webhook_subscriptions", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "user_id", null: false
    t.string "event", null: false
    t.string "target_url", null: false
    t.string "method"
    t.jsonb "event_params"
    t.boolean "active", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["active"], name: "index_webhook_subscriptions_on_active"
    t.index ["business_id"], name: "index_webhook_subscriptions_on_business_id"
    t.index ["event"], name: "index_webhook_subscriptions_on_event"
    t.index ["user_id"], name: "index_webhook_subscriptions_on_user_id"
  end

  create_table "xero_accounts", id: :serial, force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "organisation_name", null: false
    t.string "access_token", null: false
    t.string "access_key", null: false
    t.string "refresh_token"
    t.datetime "access_token_expires_at", precision: nil
    t.string "default_sales_account_code"
    t.string "default_payment_account_id"
    t.string "default_exempt_tax_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["business_id"], name: "index_xero_accounts_on_business_id", unique: true
  end

  create_table "xero_payments", id: :serial, force: :cascade do |t|
    t.integer "payment_id", null: false
    t.integer "invoice_id", null: false
    t.string "reference_payment_id", null: false
    t.string "reference_invoice_id", null: false
    t.string "payment_type", null: false
    t.datetime "synced_at", precision: nil, null: false
    t.index ["invoice_id"], name: "index_xero_payments_on_invoice_id"
    t.index ["payment_id"], name: "index_xero_payments_on_payment_id"
  end

  create_table "zoom_meetings", id: :serial, force: :cascade do |t|
    t.integer "practitioner_id", null: false
    t.integer "appointment_id", null: false
    t.string "zoom_meeting_id", null: false
    t.string "zoom_host_id", null: false
    t.integer "duration", null: false
    t.datetime "start_time", precision: nil, null: false
    t.string "start_timezone", null: false
    t.string "join_url", null: false
    t.text "start_url", null: false
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["appointment_id"], name: "index_zoom_meetings_on_appointment_id"
    t.index ["practitioner_id"], name: "index_zoom_meetings_on_practitioner_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "availabilities", "practitioners"
  add_foreign_key "treatment_contents", "treatment_template_questions", column: "question_id"
  add_foreign_key "treatment_contents", "treatment_template_sections", column: "section_id"
  add_foreign_key "treatment_contents", "treatments"
  add_foreign_key "treatment_template_questions", "treatment_template_sections", column: "section_id"
  add_foreign_key "treatment_template_sections", "treatment_templates", column: "template_id"
  add_foreign_key "treatments", "treatment_templates"
end
