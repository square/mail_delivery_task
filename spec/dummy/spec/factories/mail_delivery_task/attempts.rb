FactoryBot.define do
  factory :mail_delivery_task_attempt, class: 'MailDeliveryTask::Attempt' do
    status             { 'pending' }

    idempotence_token  { SecureRandom.hex }

    mailer_class_name  { 'DummyMailer' }
    mailer_action_name { 'action_name' }
    mailer_args        { {} }

    trait :delivered do
      status            { :delivered }
      mailer_message_id { SecureRandom.hex(6) }
      completed_at      { Time.current }
    end

    trait :expired do
      status       { 'expired' }
      completed_at { Time.current }
    end

    trait :failed do
      status       { 'failed' }
      completed_at { Time.current }
    end
  end
end
