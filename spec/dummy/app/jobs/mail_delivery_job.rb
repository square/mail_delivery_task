class MailDeliveryJob < ApplicationJob
  include MailDeliveryTask::BaseDeliveryJob
end
