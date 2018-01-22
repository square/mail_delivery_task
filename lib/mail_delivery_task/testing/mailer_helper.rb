module MailDeliveryTask
  module Testing
    module MailerHelper
      extend RSpec::Matchers::DSL

      # Tests that a provided mail object is deliverable.
      #
      # Usage:
      #
      #   expect(mail).to be_deliverable
      #
      matcher :be_deliverable do
        match do |actual|
          expect { actual.deliver_now }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
      end

      # Tests that a provided mail object has the expected attributes.
      #
      # Usage:
      #
      #   expect(mail).to have_mailer_attributes(
      #     from: 'from@.squareup.com',
      #     reply_to: 'reply_to@.squareup.com',
      #     to: ['person_1@squareup.com', 'person_2@squareup.com'],
      #     bcc: 'bcc@squareup.com',
      #     subject: 'My random subject',
      #   )
      #
      matcher :have_mailer_attributes do |from:, reply_to: nil, to:, bcc: nil, subject:|
        match(notify_expectation_failures: true) do |actual|
          expect(actual).to have_attributes(
            from: Array(from),
            reply_to: Array(reply_to),
            to: Array(to),
            bcc: Array(bcc),
            subject: subject,
          )
        end
      end

      # Tests that a string matches the content of a fixture file. Also provides
      # convenience methods to be able to update the given fixture.
      #
      # Set `update_fixture` to true in order to automatically overwrite existing
      # fixture files with latest expected text.  Note that tests will *always*
      # fail as long as `update_fixture` is set to true.
      #
      # Usage:
      #
      #   expect('my_random_text').to match_fixture('spec/fixtures/dummy.html')
      #   expect('my_random_text').to match_fixture('spec/fixtures/dummy.html', update_fixture: true)
      #
      matcher :match_fixture do |fixture_file, update_fixture: false|
        match do |actual|
          # Trim all trailing whitespace from the actual generated (to avoid
          # codebase from having any trailing whitespace)
          trimmed_actual = actual.gsub(/[ \t]+$/, '')

          if update_fixture
            # Update the fixture file with actual content
            path = File.dirname(fixture_file)
            FileUtils.mkdir_p(path)
            FileUtils.touch(fixture_file)
            File.open(fixture_file, 'w+') do |file|
              file.write(trimmed_actual)
            end

            # Make sure the spec fails
            false
          else
            begin
              expect(trimmed_actual).to eq(File.read(fixture_file))
            rescue
              # Make sure the spec fails
              false
            end
          end
        end

        failure_message do |actual|
          if update_fixture
            'Expected update_fixture to be false'
          else
            differ = RSpec::Support::Differ.new(
              object_preparer: proc { |o| RSpec::Matchers::Composable.surface_descriptions_in(o) },
              color: RSpec::Matchers.configuration.color?,
            )
            begin
              expected = File.read(fixture_file)
              <<~MESSAGE
                expected: #{expected.inspect}
                     got: #{actual.inspect}

                Diff: #{differ.diff(actual, expected)}

                To update existing fixtures, toggle the `update_fixture` option.

                Example: match_fixture('spec/fixtures/dummy.html', update_fixture: true)
              MESSAGE
            rescue
              <<~MESSAGE
                Fixture file #{fixture_file} does not exist yet. Please
                generate fixtures using the `update_fixture` option.

                Example: match_fixture('spec/fixtures/dummy.html', update_fixture: true)
              MESSAGE
            end
          end
        end
      end
    end
  end
end
