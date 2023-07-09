This is the start of an experiment to make a better alternative to
ruby Timeout.

TimeLimit is API-compatible with Timeout.

TimeLimit is implimented with
[`concurrent-ruby Concurrent::ScheduledTask`](https://github.com/ruby-concurrency/concurrent-ruby/blob/master/lib/concurrent-ruby/concurrent/scheduled_task.rb)

concurrent-ruby is well-maintained and tested, and its libraries
have known, defined semantics. This makes the implementation easier to reason about,
instead of working with an custom loop and queue sytem. (Such a system is a reasonable choice
for a stdlib gem that doesn't want to use third-party dependencies)

TimeLimit shares most behaviors with Timeout, with the following exception:
TimeLimit will always raise an exception when timing out, even if the timed
code rescues Exception. See instances of `assert s.outer_rescue # false in timeout`
in the lifecycle test suite for when this is not the case in Timeout.

In a simple benchmark, TimeLimit has about 2x the time complexity
and 2.5x the space complexity of Timeout.

