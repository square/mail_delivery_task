require 'spec_helper'

RSpec.describe MailDeliveryTask do
  it 'has a version number' do
    expect(MailDeliveryTask::VERSION).not_to be nil
  end
end
