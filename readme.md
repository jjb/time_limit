# TimeLimit

TimeLimit is API-compatible with Timeout.

TimeLimit shares most behaviors with Timeout
[(the entire test suite passes)](https://github.com/jjb/time_limit/blob/main/ruby-timeout-0.4.0-tests.rb),
with the following exception, which is its flagship feature:
TimeLimit will always raise an exception when timing out, even if the timed
code rescues Exception. See
[instances of `assert s.outer_rescue # false in timeout`](https://github.com/jjb/time_limit/blob/505e10ef123cf1993e42589527b3946d788fcb1f/test_error_lifecycle.rb#L41-L83)
in the lifecycle test suite for when this is not the case in Timeout.

## Implementation

TimeLimit is implimented with
[`concurrent-ruby Concurrent::ScheduledTask`](https://github.com/ruby-concurrency/concurrent-ruby/blob/master/lib/concurrent-ruby/concurrent/scheduled_task.rb)

concurrent-ruby is well-maintained and tested, and its libraries
have known, defined semantics. This makes the implementation easier to reason about,
instead of working with a custom loop and queue sytem. (Such a system is a reasonable choice
for Timeout as it is a stdlib gem that doesn't want to use third-party dependencies)


## Performance

In a [simple benchmark](https://github.com/jjb/time_limit/blob/main/benchmark.rb), TimeLimit has about 2x the time complexity
and 2.5x the space complexity of Timeout.

## Contributing

```
bundle
bundle exec ruby ruby-timeout-0.4.0-tests.rb
bundle exec ruby test_error_lifecycle.rb
bundle exec ruby benchmark.rb
```
