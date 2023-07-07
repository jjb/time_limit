require 'pairing_heap'

class InterruptException < Exception; end
class TimedOut < StandardError; end
class TimedOutAndRescued < TimedOut; end

@jobs_mutex = Mutex.new

@jobs_mutex.synchronize do
  @jobs = PairingHeap::MinPriorityQueue.new
end

Thread.new do
  loop do
    sleep 1

    # todo: loop through until no more relevant jobs
    j = nil
    @jobs_mutex.synchronize do
      next unless @jobs.any?
      soonest = @jobs.peek_priority
      if soonest < Time.now
        j = @jobs.pop
      end
    end
    next unless j

    j.interrupt
  end
end

class Job
  def initialize(seconds, proc, thread)
    @seconds = seconds
    @proc = proc
    @thread = thread
    @done = false
    @mutex = Mutex.new
  end

  def run
    @proc.call
  rescue InterruptException
    raise TimedOut
  rescue Exception
    raise
  else
    if @timeout_expected
      @mutex.synchronize do
        @done = true # ensure will not be reached if raising in an else
      end
      raise TimedOutAndRescued
    end
  ensure
    @mutex.synchronize do
      @done = true
    end
  end

  def interrupt
    puts "interrupting #{@thread.name}"
    @mutex.synchronize do
      return if @done
      @timeout_expected = true
      @thread.raise(InterruptException)
    end
  end
end

def w(seconds)
  p = Proc.new do
    yield
  end
  j = Job.new(seconds, p, Thread.current)
  @jobs_mutex.synchronize do
    @jobs.push(j, Time.now + seconds)
  end
  j.run
end


# idea: give an inner ensure the ability to tell the class it's in an ensure
# FunTimeout::EnsureProtector.mutext do
#   ...
# end
