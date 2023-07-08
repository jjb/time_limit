# frozen_string_literal: false
require 'test/unit'
require "core_assertions"
Test::Unit::TestCase.include Test::Unit::CoreAssertions

require_relative 'code.rb'

class TestTimeout < Test::Unit::TestCase

  def test_work_is_done_in_same_thread_as_caller
    assert_equal Thread.current, Timeout.timeout(10){ Thread.current }
  end

  def test_work_is_done_in_same_fiber_as_caller
    require 'fiber' # needed for ruby 3.0 and lower
    assert_equal Fiber.current, Timeout.timeout(10){ Fiber.current }
  end

  def test_non_timing_out_code_is_successful
    assert_nothing_raised do
      assert_equal :ok, Timeout.timeout(100){ :ok }
    end
  end

  # def test_included
  #   c = Class.new do
  #     include Timeout
  #     def test
  #       timeout(1) { :ok }
  #     end
  #   end
  #   assert_nothing_raised do
  #     assert_equal :ok, c.new.test
  #   end
  # end

  # def test_yield_param
  #   assert_equal [5, :ok], Timeout.timeout(5){|s| [s, :ok] }
  # end

  def test_queue
    q = Thread::Queue.new
    assert_raise(Timeout::TimedOut, "[ruby-dev:32935]") {
      Timeout.timeout(0.01) { q.pop }
    }
  end

  def test_timeout
    assert_raise(Timeout::TimedOut) do
      Timeout.timeout(0.1) {
        nil while true
      }
    end
  end

  def test_nested_timeout
    a = nil
    assert_raise(Timeout::TimedOut) do
      Timeout.timeout(0.1) {
        Timeout.timeout(1) {
          nil while true
        }
        a = 1
      }
    end
    assert_nil a
  end

  def test_cannot_convert_into_time_interval
    bug3168 = '[ruby-dev:41010]'
    def (n = Object.new).zero?; false; end
    assert_raise(TypeError, bug3168) {Timeout.timeout(n) { sleep 0.1 }}
  end

  def test_skip_rescue_standarderror
    e = nil
    assert_raise_with_message(Timeout::TimedOut, /execution expired/) do
      Timeout.timeout 0.01 do
        begin
          sleep 3
        rescue => e
          flunk "should not see any exception but saw #{e.inspect}"
        end
      end
    end
  end

  def test_raises_exception_internally
    e = nil
    assert_raise_with_message(Timeout::TimedOut, /execution expired/) do
      Timeout.timeout 0.01 do
        begin
          sleep 3
        rescue Exception => exc
          e = exc
          raise
        end
      end
    end
    assert_equal Timeout::InterruptException, e.class
  end

  # not supporting custom error to raise, for now
  # def test_rescue_exit
  #   exc = Class.new(RuntimeError)
  #   e = nil
  #   assert_nothing_raised(exc) do
  #     Timeout.timeout 0.01, exc do
  #       begin
  #         sleep 3
  #       rescue exc => e
  #       end
  #     end
  #   end
  #   assert_raise_with_message(exc, 'execution expired') {raise e if e}
  # end

  # def test_custom_exception
  #   bug9354 = '[ruby-core:59511] [Bug #9354]'
  #   err = Class.new(StandardError) do
  #     def initialize(msg) super end
  #   end
  #   assert_nothing_raised(ArgumentError, bug9354) do
  #     assert_equal(:ok, Timeout.timeout(100, err) {:ok})
  #   end
  #   assert_raise_with_message(err, 'execution expired') do
  #     Timeout.timeout 0.01, err do
  #       sleep 3
  #     end
  #   end
  #   assert_raise_with_message(err, /connection to ruby-lang.org expired/) do
  #     Timeout.timeout 0.01, err, "connection to ruby-lang.org expired" do
  #       sleep 3
  #     end
  #   end
  # end

  # not supporting custom error message, for now
  # def test_exit_exception
  #   assert_raise_with_message(Timeout::TimedOut, "boon") do
  #     Timeout.timeout(10, Timeout::TimedOut) do
  #       raise Timeout::TimedOut, "boon"
  #     end
  #   end
  # end

  # def test_raise_with_message
  #   bug17812 = '[ruby-core:103502] [Bug #17812]: Timeout::TimedOut doesn\'t let two-argument raise() set a new message'
  #   exc = Timeout::TimedOut.new('foo')
  #   assert_raise_with_message(Timeout::TimedOut, 'bar', bug17812) do
  #     raise exc, 'bar'
  #   end
  # end

  def test_enumerator_next
    bug9380 = '[ruby-dev:47872] [Bug #9380]: timeout in Enumerator#next'
    e = (o=Object.new).to_enum
    def o.each
      sleep
    end
    assert_raise_with_message(Timeout::TimedOut, 'execution expired', bug9380) do
      Timeout.timeout(0.01) {e.next}
    end
  end

  def test_handle_interrupt
    bug11344 = '[ruby-dev:49179] [Bug #11344]'
    ok = false
    assert_raise(Timeout::TimedOut) {
      Thread.handle_interrupt(Timeout::InterruptException => :never) {
        Timeout.timeout(0.01) {
          sleep 0.2
          ok = true
          Thread.handle_interrupt(Timeout::InterruptException => :on_blocking) {
            sleep 0.2
          }
        }
      }
    }
    assert(ok, bug11344)
  end


  # i think new watcher thread needs to be created
  # maybe cloned one needs to be cleaned up. look at ruby timeout
  def test_fork
    omit 'fork not supported' unless Process.respond_to?(:fork)
    r, w = IO.pipe
    pid = fork do
      r.close
      begin
        r = Timeout.timeout(0.01) { sleep 5; }
        w.write r.inspect
      rescue Timeout::TimedOut
        w.write 'timeout'
      ensure
        w.close
      end
    end
    w.close
    Process.wait pid
    assert_equal 'timeout', r.read
    r.close
  end

  def test_threadgroup
    assert_separately(%w[-rtimeout], <<-'end;')
      tg = ThreadGroup.new
      thr = Thread.new do
        tg.add(Thread.current)
        Timeout.timeout(10){}
      end
      thr.join
      assert_equal [].to_s, tg.list.to_s
    end;
  end

  # https://github.com/ruby/timeout/issues/24
  def test_handling_enclosed_threadgroup
    assert_separately(%w[-rtimeout], <<-'end;')
      Thread.new {
        t = Thread.current
        group = ThreadGroup.new
        group.add(t)
        group.enclose

        assert_equal 42, Timeout.timeout(1) { 42 }
      }.join
    end;
  end
end