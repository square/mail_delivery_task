ENV['RAILS_ENV'] = 'test'

require 'spec_helper'

require File.expand_path('../../spec/dummy/config/environment', __FILE__)
require 'rspec/rails'

require 'mail_delivery_task/testing'

Rails.application.load_tasks
Rake.application['db:reset'].tap(&:invoke)

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.include ActiveJob::TestHelper, type: :job
  config.include MailDeliveryTask::Testing::MailerHelper, type: :mailer

  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  # config.infer_spec_type_from_file_location!
  config.before do
    # For testing with_advisory_lock (which creates a lot of junk files)
    # https://github.com/mceachen/with_advisory_lock
    ENV['FLOCK_DIR'] = Dir.mktmpdir
  end

  config.after do
    FileUtils.remove_entry_secure ENV['FLOCK_DIR']
  end
end
