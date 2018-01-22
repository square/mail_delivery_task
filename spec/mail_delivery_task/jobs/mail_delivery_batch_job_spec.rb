require 'rails_helper'

RSpec.describe MailDeliveryBatchJob, type: :job do
  subject { described_class.new.perform }

  describe '#perform' do
    context 'with jobs that do not have scheduled_at set' do
      let!(:pending_delivery_task_1) { create(:mail_delivery_task_attempt) }
      let!(:pending_delivery_task_2) { create(:mail_delivery_task_attempt) }

      let(:global_ids) { [{'_aj_globalid' => 'gid://dummy/MailDeliveryTask::Attempt/1'}, {'_aj_globalid' => 'gid://dummy/MailDeliveryTask::Attempt/2'}] }

      it do
        subject
        expect(enqueued_jobs.map { |job| job.fetch(:args).first }).to include(*global_ids)
      end
    end

    context 'with jobs that have an scheduled_at in the past' do
      let!(:task) { create(:mail_delivery_task_attempt, scheduled_at: Time.current + 1000.days) }

      it do
        subject
        expect(enqueued_jobs).to be_empty
      end
    end
  end
end
