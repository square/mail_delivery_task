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

ActiveRecord::Schema.define(version: 20180123061915) do

  create_table "mail_delivery_task_attempts", force: :cascade do |t|
    t.integer "lock_version", default: 0, null: false
    t.string "status"
    t.string "idempotence_token", null: false
    t.string "mailer_class_name", null: false
    t.string "mailer_action_name", null: false
    t.text "mailer_args"
    t.boolean "should_persist", default: false
    t.string "mailer_message_id"
    t.string "persistence_token"
    t.integer "num_attempts", default: 0, null: false
    t.datetime "scheduled_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["completed_at"], name: "index_mail_delivery_task_attempts_on_completed_at"
    t.index ["created_at"], name: "index_mail_delivery_task_attempts_on_created_at"
    t.index ["idempotence_token", "mailer_class_name", "mailer_action_name"], name: "index_mdt_attempts_on_idempotence_token_and_mailer", unique: true
    t.index ["mailer_class_name", "mailer_action_name"], name: "index_mdt_attempts_on_mailer_and_template"
    t.index ["mailer_message_id"], name: "index_mail_delivery_task_attempts_on_mailer_message_id"
    t.index ["scheduled_at"], name: "index_mail_delivery_task_attempts_on_scheduled_at"
    t.index ["should_persist"], name: "index_mail_delivery_task_attempts_on_should_persist"
    t.index ["status"], name: "index_mail_delivery_task_attempts_on_status"
    t.index ["updated_at"], name: "index_mail_delivery_task_attempts_on_updated_at"
  end

end
