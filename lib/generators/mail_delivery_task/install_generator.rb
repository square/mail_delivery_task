require 'rails/generators'
require 'rails/generators/active_record'

module MailDeliveryTask
  class InstallGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

    source_root File.expand_path('../templates/', __FILE__)

    desc 'Generates (but does not run) migrations to add the' \
         ' mail_delivery_task_attempts table and creates the base model'

    def self.next_migration_number(dirname)
      ::ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    def create_migration_file
      migration_template 'create_mail_delivery_task_attempts.rb', 'db/migrate/create_mail_delivery_task_attempts.rb'
    end

    def create_mail_delivery_task_files
      template 'mail_delivery_task_attempt.rb.erb', 'app/models/mail_delivery_task/attempt.rb'
      template 'mail_delivery_job.rb.erb', 'app/jobs/mail_delivery_job.rb'
      template 'mail_delivery_batch_job.rb.erb', 'app/jobs/mail_delivery_batch_job.rb'

      if defined?(RSpec)
        template 'mail_delivery_task_attempt_spec.rb.erb', 'spec/models/mail_delivery_task/attempt_spec.rb'
        template 'mail_delivery_job_spec.rb.erb', 'spec/jobs/mail_delivery_job_spec.rb'
        template 'mail_delivery_batch_job_spec.rb.erb', 'spec/jobs/mail_delivery_batch_job_spec.rb'
      end

      if defined?(FactoryBot) || defined?(FactoryGirl)
        template 'mail_delivery_task_attempts.rb.erb', 'spec/factories/mail_delivery_task/attempts.rb'
      end
    end
  end
end
