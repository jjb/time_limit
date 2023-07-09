# bundle exec ruby benchmark.rb

require 'benchmark/ips'

require_relative 'time_limit.rb'
require 'timeout'


def the_code(the_class)
  threads = []
  100.times do
    threads << Thread.new do
      value = the_class.timeout(1) {:ok}
    end
  end
  threads.each(&:join)
end

Benchmark.ips do |x|
  x.report("TimeLimit") do
    the_code(TimeLimit)
  end

  x.report("Timeout") do
    the_code(Timeout)
  end

  x.compare!
end
