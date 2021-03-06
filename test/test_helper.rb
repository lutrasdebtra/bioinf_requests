ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  # Model helpers - rake test  "test/models/**/*_test.rb"#
  def create_changed_request
    request = Request.new
    request.title = 'Request'
    request.name = 'stuart.bradley'
    request.status = 'Pending'
    request.save

    request.title = 'Request Changed'
    request.save
    request
  end

  def same_elements?(array1, array2)
    array1.to_set == array2.to_set
  end
end
