require 'rails_helper'

RSpec.describe MailDeliveryTask::Attempt, type: :model do
  describe '#deliver!' do
    let(:action_name) { 'action_name' }
    let(:message_id) { "1" }

    subject { task.deliver! }

    context 'when the task is not scheduled yet' do
      let!(:task) { create(:mail_delivery_task_attempt, scheduled_at: Time.current + 1000.days) }

      it { expect { subject }.to_not change { task.num_attempts } }
    end

    context 'when the task is not pending' do
      let(:task) { create(:mail_delivery_task_attempt, :failed) }

      it 'raises an InvalidStateError' do
        expect { subject }.to raise_error(MailDeliveryTask::InvalidStateError)
      end
    end

    context 'when the task is pending' do
      context 'when the delivery succeeds' do
        let(:task) { create(:mail_delivery_task_attempt) }

        it 'sets the mailer_message_id' do
          expect { subject }.to change(task, :mailer_message_id).from(nil).to(message_id)
          expect(task.status).to eq('delivered')
        end

        context 'when should_persist is true' do
          let(:task) { create(:mail_delivery_task_attempt, should_persist: true) }

          it 'sets the persistence token' do
            subject
            expect(task.persistence_token.length).to be(32)
          end
        end

        context 'when should_persist is false' do
          let(:task) { create(:mail_delivery_task_attempt, should_persist: false) }

          it 'does not set the persistence token' do
            expect { subject }.not_to change(task, :persistence_token)
          end
        end
      end

      context 'when the delivery fails with any error' do
        let(:task) { create(:mail_delivery_task_attempt) }

        before { allow(DummyMailer).to receive(:action_name).and_raise(RuntimeError) }

        it 'increments num_attempts' do
          expect { subject }.to raise_error(RuntimeError)
          expect(task.num_attempts).to eq(1)
        end
      end
    end
  end

  describe '#expire!' do
    subject { task.expire! }

    context 'with a pending task' do
      let(:task) { create(:mail_delivery_task_attempt) }

      it 'sets completed_at and status to expired' do
        expect { subject }.to change { task.status }.from('pending').to('expired')
        expect(task.completed_at).not_to be_nil
      end
    end

    context 'with a non-pending task' do
      let(:task) { create(:mail_delivery_task_attempt, :failed) }

      it 'sets raises an InvalidStateError' do
        expect { subject }.to raise_error(MailDeliveryTask::InvalidStateError)
      end
    end
  end

  describe '#fail!' do
    subject { task.fail! }

    context 'with a pending task' do
      let(:task) { create(:mail_delivery_task_attempt) }

      it 'sets completed_at and status to failed' do
        expect { subject }.to change { task.status }.from('pending').to('failed')
        expect(task.completed_at).not_to be_nil
      end
    end

    context 'with a non-pending task' do
      let(:task) { create(:mail_delivery_task_attempt, :expired) }

      it 'sets raises an InvalidStateError' do
        expect { subject }.to raise_error(MailDeliveryTask::InvalidStateError)
      end
    end
  end
end
