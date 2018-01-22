class MailDeliveryTask::Attempt < ApplicationRecord
  include MailDeliveryTask::BaseAttempt

  # @override
  #
  # Override this method to deliver mail.
  def persist_mail(mail)
    SecureRandom.hex
  end

  # @override
  #
  # This method is used by MailDeliveryTask::BaseAttempt when #perform! fails.
  def handle_deliver_mail_error(error)
    raise error
  end

  # @override
  #
  # This method is used by MailDeliveryTask::BaseAttempt when #perform! fails.
  def handle_persist_mail_error(error)
    raise error
  end
end
