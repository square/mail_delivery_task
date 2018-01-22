# MailDeliveryTask

[![Gem Version](https://badge.fury.io/rb/mail_delivery_task.svg)](http://badge.fury.io/rb/mail_delivery_task)
[![License](https://img.shields.io/badge/license-Apache-green.svg?style=flat)](https://github.com/square/mail_delivery_task/blob/master/LICENSE)

This gem provides generators and mixins to queue up mail delivery in database transactions to be
delivered later. Doing so prevents mail from being sent twice if the transaction is rolled back:

```ruby
transaction do
  model = MyModel.create!(foo: 'hello')
  MyMailer.mailer_action(model: model).deliver
  raise
end
```

Despite database transaction rolling back the creation of the `MyModel` record, the mail is still
delivered. This problem becomes more difficult in nested transactions. To avoid this, we create a
a `MailDeliveryTask::Attempt` record inside the database. These records are then delivered at a
later time using a job:

```ruby
transaction do
  model = MyModel.create!(foo: 'hello')

  # To be sent by a job later
  MailDeliveryTask::Attempt.create(
    mailer_class: MyMailer,
    mailer_action_name: :mailer_action,
    mailer_args: { my_model: model },
    idempotence_token: "my_model##{id}"
  )

  raise
end
```

The above pattern ensures mail delivery tasks will not be created nor sent when the transaction
fails.

The gem provides the following:

* Models
  * Generators for the `MailDeliveryTask::Attempt` migration, model, factory, and specs.
  * Tracking completion using `completed_at`.
  * Fields for `mailer_class_name`, `mailer_action_name`, and `mailer_args`.
  * `MailDeliveryTask::BaseAttempt` mixin to provide model methods.
  * Persistence token support.
  * A `num_attempts` field gives you flexibility to handle retries and other failure scenarios.
  * `status` and `completed_at` are fields that track state.
* Jobs
  * Generators for `MailDeliveryTaskJob` and `MailDeliveryBatchJob` jobs and specs
  * `MailDeliveryTask::BaseDeliveryJob` and `MailDeliveryTask::BaseDeliveryBatchJob` mixins.

## Design Motivations

We're relying heavily on generators and mixins. Including the `MailDeliveryTask::BaseAttempt` module
allows us to generate a model that can inherit from both `ActiveRecord::Base` (Rails 4) and
`ApplicationRecord` (Rails 5). The `BaseAttempt` module's methods can easily be overridden, giving
callers flexibility to handle errors, extend functionality, and inherit (STI). Lastly, the generated
migrations provide fields used by the `BaseAttempt` module, but the developer is free to add their
own fields and extend the module's methods while calling `super`.

This gem is also designed to be compatible with any `ApplicationMailer` implementation through the
use of the `mailer_class_name`, `mailer_action_name`, and `mailer_args` (keyword args) fields.

## Getting Started

1. Add the gem to your application's Gemfile and execute `bundle install` to install it:

```ruby
gem 'mail_delivery_task'
```

2. Generate migrations, base models, jobs, and specs. Feel free to add any additional columns you
may need to the generated migration file:

`$ rails generate mail_delivery_task:install`

3. You will need a working `ActionMailer` class to send mail through SMTP / Butter. **Note: the
mailer's arguments MUST be keyword arguments to be compatible with the `mailer_args` field in the
`MailDeliveryTask` model.**

```ruby
class DummyMailer < ApplicationMailer
  # Keyword args required!!!
  def action_name(to_address:)
    mail(
      to: to_address,
      subject: 'How to setup mail_delivery_task',
      body: "It's really easy.",
      content_type: 'text/plain',
    )
  end
end
```

4. Rename the model and migrations as you see fit. Make sure your model contains
`include MailDeliveryTask::BaseAttempt`.

```ruby
class MailDeliveryTask < ActiveRecord::Base
  include MailDeliveryTask::BaseAttempt
end
```

5. Implement the `handle_deliver_mail_error` and `handle_persist_mail_error` in your `MailDeliveryTask`
model. These two methods are used by `MailDeliveryTask::BaseAttempt` when exceptions are thrown
delivering and persisting the mail. See cookbook below for details on persistence and error
handling.

6. Do not send mail directly using the `ActionMailer` class above. Instead, create
`MailDeliveryTask`s to be sent later by a job (generated) that includes a
`MailDeliveryTask::BaseDeliveryJob`:

```ruby
class MailDeliveryJob < ActiveJob::Base
  include MailDeliveryTask::BaseDeliveryJob
end
```

```ruby
transaction do
  # Using the DummyMailer class above...
  MailDeliveryTask::Attempt.create(
    mailer_class: DummyMailer,
    mailer_action_name: :action_name,
    mailer_args: { to_address: 'jchang@squareup.com' },
    idempotence_token: 'token',
  )
end
```

7. **Make sure to schedule the mail delivery job to run frequently using [`Clockwork`](https://github.com/adamwiggins/clockwork).**

## Improper Uses of the Gem

Below are patterns that defeat the purpose of using this gem:

```ruby
# DO NOT DO THIS
transaction do
  task = create_mail_delivery_task
  task.deliver!
  raise
end
```

The above example allows mail to be delivered even if the transaction fails.

```ruby
# DO NOT DO THIS
MailDeliverytask::Attempt.create!(
  mailer_class: 'DummyMailer',
  mailer_action_name: 'action_name',
  mailer_args: {},
).deliver!
```

These two examples above do not make use of a job to deliver mail.

## Cookbook

### Delayed Execution

Setting the `scheduled_at` field allows delayed execution to be possible. A task that has an
`scheduled_at` before `Time.current` will be executed by `MailDeliveryTask::BaseDeliveryBatchJob`.

### Overriding MailDeliveryTask::Base Error Handlers

By default, when persistence or deliverance fails, it just raises the error
encountered. However, if you want to raise a custom error or wrap the error,
you can override both of these by overriding the `handle_deliver_mail_error`
and `handle_persist_mail_error` methods.

```ruby
class MailDeliveryTask::Attempt < ApplicationRecord
  include MailDeliveryTask::BaseAttempt

  class DeliverMailError < StandardError; end
  class PersistMailError < StandardError; end

  def handle_deliver_mail_error(error)
    raise DeliverMailError, 'my custom error message'
  end

  def handle_persist_mail_error(error)
    raise PersistMailError, 'my custom error message'
  end
end
```

Lastly, the `num_attempts` field in `MailDeliveryTask::Attempt` allows you to track the number of
delivery attempts the mail has. Use this to implement retries and permanent failure thresholds for
your mail delivery tasks.

### Proper Usage of `expire!` / `fail!`

`expire!` should be used for mail that is no longer applicable, such as a mail for plan past due
when the plan is no longer past due.

`fail!` should be used to mark delivery as failed when the mail should have been, but was not,
delivered successfully.

### Persistence

If you wish to persist mail, override the `persist_mail` method:

```ruby
class MailDeliveryTask::Attempt < ApplicationRecord
  include MailDeliveryTask::BaseAttempt

  private

  def persist_mail(mail)
    store_in_s3(mail.to_s)
  end
end
```

Don't forget to set the `persistence_token`.

### Custom Matchers for RSpec

Add the following lines to `rails_helper.rb`:

```ruby
require 'mail_delivery_task/testing'

RSpec.configure do |config|
  config.include MailDeliveryTask::Testing::MailerHelper, type: :mailer
end
```

Now custom matchers like `be_deliverable` are enabled:

```ruby
expect(mail).to be_deliverable
```

For a full list of matchers, see [here](https://github.com/square/mail_delivery_task/tree/master/lib/mail_delivery_task/testing/mailer_helper.rb).

### Overriding the Mail Delivery Mechanism

Sometimes the mail delivery method found in the [BaseAttempt](https://github.com/square/mail_delivery_task/tree/master/lib/mail_delivery_task/base_attempt.rb) is insufficient. In this case you can override the method in your `MailDeliveryTask::Attempt`:

```ruby
class MailDeliveryTask::Attempt < ApplicationRecord
  include MailDeliveryTask::BaseAttempt

  private

  def deliver_mail(mail)
    mail.deliver_some_other_way
  end
end
```

## Development

* Install dependencies with `bin/setup`.
* Run tests/lints with `rake`
* For an interactive prompt that will allow you to experiment, run `bin/console`.

## License

```
Copyright 2017 Square, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
