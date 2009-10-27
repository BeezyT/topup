# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091027224443) do

  create_table "comments", :force => true do |t|
    t.string   "name"
    t.string   "email_address"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "unsubscription_code"
  end

  create_table "release_info", :id => false, :force => true do |t|
    t.string "version"
  end

  create_table "trackers", :force => true do |t|
    t.string   "name"
    t.string   "email_address"
    t.boolean  "is_inactive"
    t.text     "tracked_versions"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "unsubscription_code"
  end

end
