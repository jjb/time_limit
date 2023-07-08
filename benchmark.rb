require 'benchmark/ips'

require_relative 'time_limit.rb'
require 'timeout'

Benchmark.ips do |x|
  x.report("T") do
    value = Timeout.timeout(1) {:ok}
  end
end

Benchmark.ips do |x|
  x.report("TimeLimit") do
    value = Timeout.timeout(1) {:ok}
  end
end
