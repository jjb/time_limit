# require 'pairing_heap'

require 'concurrent/scheduled_task'

module TimeLimit
  class InterruptException < Exception; end
  class TimedOut < StandardError; end

  class Job
    def initialize(proc, seconds, thread, custom_exception_class, message)
      @proc = proc
      @thread = thread
      @custom_exception_class = custom_exception_class
      @interrupt_exception_class = custom_exception_class || InterruptException
      @message = message || 'execution expired'
      @done = false
      @mutex = Mutex.new
      @watcher = Concurrent::ScheduledTask.new(seconds){ self.interrupt }.execute
    end

    def run
      r = @proc.call
    rescue InterruptException
      raise TimedOut.new(@message)
    else
      if @timeout_expected
        if @custom_exception_class
          raise @custom_exception_class.new(@message)
        else
          raise TimedOut.new(@message)
        end 
      else
        r
      end
    ensure
      @mutex.synchronize do
        @done = true
        @watcher.cancel
      end
    end

    def interrupt
      @mutex.synchronize do
        return if @done
        @timeout_expected = true
        @thread.raise(@interrupt_exception_class, @message)
      end
    end
  end

  def timeout(seconds, exception_class=nil, message=nil)
    return yield(seconds) if seconds == nil or seconds.zero? # currently untested https://github.com/ruby/timeout/pull/40
    seconds = Float(seconds)

    p = Proc.new do
      yield seconds
    end
    j = Job.new(p, seconds, Thread.current, exception_class, message)
    j.run
  end
  module_function :timeout
end
