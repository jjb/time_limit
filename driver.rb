require_relative 'code.rb'

t1 = Thread.new do
  Thread.current.name = 't1'
begin
  Timeout.timeout(4) do
    begin
      sleep 6
    rescue Exception
      puts "haha i rescued!"
    end
    puts "inside"
  end
  puts "done"
rescue #TimedOut
  puts $!
  puts 'outer code is healthy'
end
end

t2 = Thread.new do
    Thread.current.name = 't2'
begin
  Timeout.timeout(1) do
    begin
      sleep 2
    rescue 
      puts "haha i rescued2!"
    end
    puts "inside2"
  end
  puts "done2"
rescue #TimedOut
  puts $!
  puts 'outer code is healthy2'
end
end

puts
puts "starting..."
Timeout.timeout(1) do
    Thread.current.name = 'fast'
  puts "running..."
end
puts "ending..."
puts


t1.join
t2.join
