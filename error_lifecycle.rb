
# https://github.com/jjb/timeout/tree/lifecycle-tests/test

class MyStandardError < StandardError; end
class MyException< Exception; end

class ErrorLifeCycleTester
  attr_reader :inner_attempted, :inner_else, :inner_rescue, :inner_ensure, :inner_ensure_has_time_to_finish,
              :outer_rescue, :outer_else, :outer_ensure, :outer_ensure_has_time_to_finish

  def subject(error_to_rescue)
    @inner_attempted = false
    @inner_else = false
    @inner_rescue = false
    @inner_ensure = false
    @inner_ensure_has_time_to_finish = false

    @outer_rescue = false
    @outer_else = false
    @outer_ensure = false
    @outer_ensure_has_time_to_finish = false

    begin
      TimeLimit.timeout(0.001) do
        @inner_attempted = true
        nil while true
      rescue error_to_rescue
        @inner_rescue = true
      else
        @inner_else = true
      ensure
        @inner_ensure = true
        t = Time.now; nil while Time.now < t+1
        @inner_ensure_has_time_to_finish = true
      end
    rescue Exception
      @outer_rescue = true
    else
      @outer_else = true
    ensure
      @outer_ensure = true
      t = Time.now; nil while Time.now < t+1
      @outer_ensure_has_time_to_finish = true
    end

    # this is here to avoid cluttering the "UNDESIRED?" section of each test,
    # can be flatted into the main tests
    unless @outer_else ^ @outer_rescue
      raise "something strange happened with the outer_rescue variables"
    end
  end
end
