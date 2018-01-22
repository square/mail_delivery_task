require 'rails_helper'

RSpec.describe MailDeliveryJob, type: :job do
  describe '#perform' do
    let!(:pending_task) { create(:mail_delivery_task_attempt) }

    subject { described_class.new.perform(pending_task) }

    before { allow(pending_task).to receive(:deliver!).and_call_original }

    it 'calls deliver! on the mail delivery task' do
      subject
      expect(pending_task).to have_received(:deliver!)
    end
  end
end
