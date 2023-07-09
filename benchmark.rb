# bundle exec ruby benchmark.rb

require 'benchmark/ips'

require_relative 'time_limit.rb'
require 'timeout'

Benchmark.ips do |x|
  x.report("Timeout") do
    value = Timeout.timeout(1) {:ok}
  end
end

Benchmark.ips do |x|
  x.report("TimeLimit") do
    value = TimeLimit.timeout(1) {:ok}
  end
end
