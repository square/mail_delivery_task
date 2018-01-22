module MailDeliveryTask
  module BaseDeliveryBatchJob
    extend ActiveSupport::Concern

    included do
      include MailDeliveryTask::BaseJob
      queue_as :default
    end

    def perform
      unless_already_executing do
        ::MailDeliveryTask::Attempt.pending.where('scheduled_at IS ? || scheduled_at < ?', nil, Time.current).find_each do |task|
          ::MailDeliveryJob.perform_later(task)
        end
      end
    end
  end
end
