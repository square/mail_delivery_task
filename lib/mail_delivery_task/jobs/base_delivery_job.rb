module MailDeliveryTask
  module BaseDeliveryJob
    extend ActiveSupport::Concern

    included do
      include MailDeliveryTask::BaseJob
      queue_as :default

      # @override
      private def lock_key
        [self.class.name, @task.id]
      end
    end

    def perform(task)
      @task = task

      unless_already_executing do
        @task.deliver! if @task.reload.pending?
      end
    end
  end
end
