# require 'pairing_heap'

require 'concurrent/scheduled_task'

module TimeLimit
  class InterruptException < Exception; end
  class TimedOut < StandardError; end
  class TimedOutAndRescued < TimedOut; end

  class Job
    def initialize(proc, thread, exception_class, message)
      @proc = proc
      @thread = thread
      @exception_class = exception_class || TimedOut
      @message = message || 'execution expired'
      @done = false
      @mutex = Mutex.new
    end

    def run
      r = @proc.call
    rescue InterruptException
      raise @exception_class.new(@message)
    rescue Exception
      raise
    else
      if @timeout_expected
        @mutex.synchronize do
          @done = true # ensure will not be reached if raising in an else
        end
        raise TimedOutAndRescued
      else
        r
      end
    ensure
      @mutex.synchronize do
        @done = true
      end
    end

    def interrupt
      @mutex.synchronize do
        return if @done
        @timeout_expected = true
        @thread.raise(InterruptException)
      end
    end
  end

  def timeout(seconds, exception_class=nil, message=nil)
    # this works but maybe by accident because Float() raises the error
    raise ArgumentError.new('seconds must be greater than zero') if Float(seconds) < 0.0

    p = Proc.new do
      yield
    end
    j = Job.new(p, Thread.current, exception_class, message)
    Concurrent::ScheduledTask.new(seconds){ j.interrupt }.execute
    j.run
  end
  module_function :timeout
end

# idea: give an inner ensure the ability to tell the class it's in an ensure
# TimeLimit::EnsureProtector.mutext do
#   ...
# end
#
# https://ruby-doc.org/core-2.5.0/Thread.html#method-c-handle_interrupt
