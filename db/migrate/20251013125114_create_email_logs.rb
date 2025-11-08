class CreateEmailLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :email_logs do |t|
      t.string :recipient, null: false
      t.string :subject, null: false
      t.string :template, null: false
      t.text :payload_json
      t.string :provider_message_id
      t.integer :status, default: 0

      t.timestamps
    end
    add_index :email_logs, :status
  end
end
