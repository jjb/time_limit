# require 'pairing_heap'

require 'concurrent/scheduled_task'

module TimeLimit
  class InterruptException < Exception; end
  class TimedOut < StandardError; end
  # class TimedOutAndRescued < TimedOut; end

  class Dummy; end

  class Job
    def initialize(proc, thread, custom_exception_class, message)
      @proc = proc
      @thread = thread
      @custom_exception_class = custom_exception_class || Dummy
      @interrupt_exception_class = custom_exception_class || InterruptException
      # @timeout_exception_class = custom_exception_class || TimedOut 
      @message = message || 'execution expired'
      @done = false
      @mutex = Mutex.new
    end

    def run
      r = @proc.call
    rescue @custom_exception_class
      raise
    rescue InterruptException
      raise TimedOut.new(@message)
    rescue Exception
      raise
    else
      if @timeout_expected
        case @custom_exception_class
        when Dummy
          raise TimedOut.new(@message)
        else
          raise @interrupt_exception_class.new(@message)
        end 
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
        @thread.raise(@interrupt_exception_class, @message) # test if removing message makes a test fail
      end
    end
  end

  def timeout(seconds, exception_class=nil, message=nil)
    # this works but maybe by accident because Float() raises the error
    raise ArgumentError.new('seconds must be greater than zero') if Float(seconds) < 0.0

    p = Proc.new do
      yield seconds
    end
    j = Job.new(p, Thread.current, exception_class, message)
    Concurrent::ScheduledTask.new(seconds){ j.interrupt }.execute
    j.run
  end
  module_function :timeout
end
