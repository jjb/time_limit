require 'pairing_heap'

module Timeout
  class InterruptException < Exception; end
  class TimedOut < StandardError; end
  class TimedOutAndRescued < TimedOut; end

  GET_TIME = Process.method(:clock_gettime)
  private_constant :GET_TIME

  JOBS_MUTEX = Mutex.new

  JOBS_MUTEX.synchronize do
    JOBS = PairingHeap::MinPriorityQueue.new
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
      r = @proc.call
    rescue InterruptException
      raise TimedOut.new('execution expired')
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

  def self.timeout(seconds)
    create_watcher_thread
    p = Proc.new do
      yield
    end
    j = Job.new(seconds, p, Thread.current)
    JOBS_MUTEX.synchronize do
      JOBS.push(j, GET_TIME.call(Process::CLOCK_MONOTONIC) + seconds)
    end

    j.run
  end

  def self.create_watcher_thread
    return if @watcher && @watcher.alive?
    @watcher ||= Thread.new do
      loop do
        sleep 0.001

        # todo: loop through until no more relevant jobs
        j = nil
        JOBS_MUTEX.synchronize do
          next unless JOBS.any?
          soonest = JOBS.peek_priority
          if soonest < GET_TIME.call(Process::CLOCK_MONOTONIC)
            j = JOBS.pop
          end
        end
        next unless j

        j.interrupt
      end
    end

    # ruby timeoyt does these, unsure why, doesn't help fork test work
    ThreadGroup::Default.add(@watcher) unless @watcher.group.enclosed?
    @watcher.thread_variable_set(:"\0__detached_thread__", true)
  end

end

# idea: give an inner ensure the ability to tell the class it's in an ensure
# FunTimeout::EnsureProtector.mutext do
#   ...
# end
#
# https://ruby-doc.org/core-2.5.0/Thread.html#method-c-handle_interrupt
