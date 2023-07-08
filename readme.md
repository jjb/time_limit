This is the start of an experiment to make a better alternative to
ruby Timeout.

TimeLimit is API-compatible with Timeout.

In a simple benchmark, TimeLimit has similar time complexity to Timeout.
I haven't tried measuring space complexity.

TimeLimit shares most behaviors with Timeout, with the following exceptions:

## Always raises an exception when timing out

TimeLimit will always raise an exception when timing out, even if the timed
code rescues Exception.

## Never raises the custom exception inside the timed code

If providing a custom exception, Timeout will (sometimes?) raise
that exception inside the timed code, instead of ExitException. I'm
not sure if this is considered a feature, or a historical necesity.
I can't think of a scenario where it's useful. The timed code
needs to know to expect this exception. If it has that level of knowledge,
why not just not provide a custom exception and rescue ExitException instead?
I'm still exploring this one.

In TimeLimit, the custom exception will still be raised externally to the
calling code.

## Implimented with concurrent-ruby Concurrent::ScheduledTask

concurrent-ruby is well-maintained and tested, and its libraries
have known, defined semantics. This makes the implementation easier to reason about,
instead of working with an custom loop and queue sytem. (Such a system is a reasonable choice
for a stdlib gem that doesn't want to use third-party dependencies)

## Coming soon: an experimental tool for avoiding ensure blocks being interrupted

```ruby
...
ensure
  TimeLimit::EnsureProtector.mutext do
    ...
  end
end
```
