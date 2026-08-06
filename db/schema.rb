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

ActiveRecord::Schema[8.1].define(version: 2026_08_06_224423) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "clients", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "landing_pages", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.string "slug"
    t.string "template"
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_landing_pages_on_client_id"
    t.index ["slug"], name: "index_landing_pages_on_slug", unique: true
  end

  create_table "photos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "file_description"
    t.integer "position"
    t.bigint "section_id", null: false
    t.datetime "updated_at", null: false
    t.index ["section_id"], name: "index_photos_on_section_id"
  end

  create_table "sections", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.bigint "landing_page_id", null: false
    t.integer "position"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["landing_page_id"], name: "index_sections_on_landing_page_id"
  end

  add_foreign_key "landing_pages", "clients"
  add_foreign_key "photos", "sections"
  add_foreign_key "sections", "landing_pages"
end
