module MailDeliveryTask
  class InvalidStateError < StandardError; end

  module BaseAttempt
    extend ActiveSupport::Concern

    included do
      extend Enumerize

      self.table_name = 'mail_delivery_task_attempts'

      validates :mailer_class_name, presence: true
      validates :mailer_action_name, presence: true
      validates :mailer_message_id, uniqueness: true, allow_nil: true

      serialize :mailer_args, JSON

      scope :persisted, -> { where.not(persistence_token: nil) }
      scope :pending, -> { where(status: :pending) }
      scope :delivered, -> { where(status: :delivered) }
      scope :expired, -> { where(status: :expired) }
      scope :failed, -> { where(status: :failed) }

      enumerize :status,
                in: [:pending, :delivered, :expired, :failed],
                predicates: true

      before_create do
        self.status ||= 'pending'
      end

      # For backward compatibility
      alias_method :handle_deliver_error, :handle_deliver_mail_error
    end

    def deliver!
      return unless may_schedule?

      begin
        reload
        raise MailDeliveryTask::InvalidStateError unless pending?
        increment!(:num_attempts)
      rescue ActiveRecord::StaleObjectError
        retry
      end

      mailer_class = mailer_class_name.constantize

      mail = if mailer_args.present?
        mailer_class.send(mailer_action_name, **mailer_args.symbolize_keys)
      else
        mailer_class.send(mailer_action_name)
      end

      with_lock do
        raise MailDeliveryTask::InvalidStateError unless pending?

        begin
          self.persistence_token = persist_mail(mail) if should_persist?
        rescue StandardError => e
          # If Trunk is down, simply catch the exception so that we won't retry
          # and thus send the mail multiple times.
          handle_persist_mail_error(e)
        end

        begin
          # Perform the actual delivery through SMTP / Butter
          deliver_mail(mail)

          # Note that this fails silently.
          self.mailer_message_id = mail.message_id
          update_status!('delivered')
        rescue StandardError => e
          handle_deliver_error(e)
        end
      end
    end

    def expire!
      with_lock do
        raise MailDeliveryTask::InvalidStateError unless pending?
        update_status!('expired')
      end
    end

    def fail!
      with_lock do
        raise MailDeliveryTask::InvalidStateError unless pending?
        update_status!('failed')
      end
    end

    def may_schedule?
      scheduled_at.blank? || scheduled_at < Time.current
    end

    private

    def deliver_mail(mail)
      mail.deliver
    end

    # Override this if needed.
    def persist_mail(mail)
      raise NotImplementedError
    end

    # Override this if needed.
    def handle_deliver_mail_error(e)
      raise(e)
    end

    # Override this if needed.
    def handle_persist_mail_error(e)
      raise(e)
    end

    def update_status!(status)
      update!(
        status: status,
        completed_at: Time.current,
      )
    end
  end
end
