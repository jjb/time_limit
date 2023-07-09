# bundle exec ruby benchmark.rb

require 'benchmark/ips'

require_relative 'time_limit.rb'
require 'timeout'

Benchmark.ips do |x|
  x.report("TimeLimit") do
    threads = []
    100.times do
      threads << Thread.new do
        value = TimeLimit.timeout(1) {:ok}
      end
    end
    threads.each(&:join)
  end
end

Benchmark.ips do |x|
  x.report("Timeout") do
    threads = []
    100.times do
      threads << Thread.new do
        value = Timeout.timeout(1) {:ok}
      end
    end
    threads.each(&:join)
  end
end
