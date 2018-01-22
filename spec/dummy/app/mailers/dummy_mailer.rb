class DummyMailer < ApplicationMailer
  def action_name
    mail(
      to: 'test@squareup.com',
      subject: 'test subject',
      body: 'test body',
      content_type: 'text/plain',
      message_id: '1'
    )
  end
end
