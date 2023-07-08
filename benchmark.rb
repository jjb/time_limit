require 'benchmark/ips'

require_relative 'code.rb'
Benchmark.ips do |x|
  x.report("weird_timeout") do
    Timeout.timeout(1) {}
  end
end

require 'timeout'
Benchmark.ips do |x|
  x.report("timeout") do
    Timeout.timeout(1) {}
  end
end