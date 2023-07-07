require 'pairing_heap'

class InterruptException < Exception; end
class TimedOut < StandardError; end
class TimedOutAndRescued < TimedOut; end

JOBS_MUTEX = Mutex.new

JOBS_MUTEX.synchronize do
  JOBS = PairingHeap::MinPriorityQueue.new
end

Thread.new do
  loop do
    sleep 0.001

    # todo: loop through until no more relevant jobs
    j = nil
    JOBS_MUTEX.synchronize do
      next unless JOBS.any?
      soonest = JOBS.peek_priority
      if soonest < Time.now
        j = JOBS.pop
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
    puts 1
    r = @proc.call
  rescue InterruptException
    puts 2
    raise TimedOut.new('execution expired')
  rescue Exception
    puts 3

    raise
  else
    puts 4
        # require 'irb'; binding.irb
    if @timeout_expected
      @mutex.synchronize do
        @done = true # ensure will not be reached if raising in an else
      end
      raise TimedOutAndRescued
    else
      r
    end
  ensure
    puts 5
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

module Timeout
  def self.timeout(seconds)
    p = Proc.new do
      yield
    end
    j = Job.new(seconds, p, Thread.current)
    JOBS_MUTEX.synchronize do
      JOBS.push(j, Time.now + seconds)
    end
        # require 'irb'; binding.irb

    j.run
  end
end


# idea: give an inner ensure the ability to tell the class it's in an ensure
# FunTimeout::EnsureProtector.mutext do
#   ...
# end
