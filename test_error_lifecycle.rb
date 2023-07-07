require 'test/unit'
require "core_assertions"
Test::Unit::TestCase.include Test::Unit::CoreAssertions

require_relative 'code.rb'

class TestErrorLifecycle < Test::Unit::TestCase

  # Behavior marked "UNDESIRED?" is done so as John's opinion, these can/should be removed before the PR is merged

  require_relative 'error_lifecycle.rb'

  def core_assertions(s)
    assert s.inner_attempted
    assert !s.inner_else
    assert s.inner_ensure
    assert s.outer_ensure
    assert s.outer_rescue

    # This can result in user's expectation of total possible time
    # being very wrong
    # t = Time.now; Timeout.timeout(0.1){begin; sleep 1; ensure; sleep 2; end} rescue puts Time.now-t
    # => 2.106306
    assert s.inner_ensure_has_time_to_finish
    assert s.outer_ensure_has_time_to_finish
  end

  # when the inner code does not catch Exception
  def test_1
    s = ErrorLifeCycleTester.new
    s.subject(StandardError)
    core_assertions(s)

    assert !s.inner_rescue
  end

  # when the inner code does catch Exception
  def test_2
    s = ErrorLifeCycleTester.new
    s.subject(Exception)
    core_assertions(s)

    assert s.inner_rescue
  end

end
