class CreateMailDeliveryTaskAttempts < ActiveRecord::Migration[5.1]
  def change
    create_table :mail_delivery_task_attempts do |t|
      t.integer       :lock_version, null: false, default: 0

      t.string        :status
      t.string        :idempotence_token, null: false

      t.string        :mailer_class_name, null: false
      t.string        :mailer_action_name, null: false
      t.text          :mailer_args

      t.boolean       :should_persist, default: false
      t.string        :mailer_message_id
      t.string        :persistence_token

      t.integer       :num_attempts, null: false, default: 0

      t.datetime      :scheduled_at
      t.datetime      :completed_at

      t.timestamps    null: false

      t.index :status
      t.index [:idempotence_token, :mailer_class_name, :mailer_action_name], unique: true, name: 'index_mdt_attempts_on_idempotence_token_and_mailer'

      t.index [:mailer_class_name, :mailer_action_name], name: 'index_mdt_attempts_on_mailer_and_template'

      t.index :should_persist
      t.index :mailer_message_id

      t.index :scheduled_at
      t.index :completed_at

      t.index :created_at
      t.index :updated_at
    end
  end
end
