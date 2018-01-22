class MailDeliveryBatchJob < ApplicationJob
  include MailDeliveryTask::BaseDeliveryBatchJob
end
