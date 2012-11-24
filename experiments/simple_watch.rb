# The purpose of this experiment is to show that the planner is capable of
# generating a long sequence diagram (in terms of the number of method calls)
# that is presented in a software engineering book. The sequence diagram in
# question is the one for the SimpleWatch (aka 2Bwatch) system depicted in
# Figure 2-34 of Object-Oriented Software Engineering Using UML, Patterns, and
# Java by Bernd Bruegge and Allen H. Dutoit.

require_relative 'experiment_helpers'


display = DbcObject.new('display', :TwoBWatchDisplay, {
  :@blinking => :none,
  :@is_refreshed => false,
  :@watch => nil
})

time = DbcObject.new('time', :TwoBWatchTime, {
  :@is_minutes_incremented => false,
  :@is_new_time_committed => false,
  :@watch => nil
})

watch = DbcObject.new('watch', :TwoBWatchInput, {
  :@last_buttons_pressed => [],
  :@mode => :read_time,
  :@display => display,
  :@time => time
})

watch.boundary_object = true
display.watch = watch
time.watch = watch


# TwoBWatchDisplay methods
blink_hours = DbcMethod.new(:blink_hours)
blink_hours.precondition = Proc.new do
  @watch.mode == :set_time &&
    @watch.last_buttons_pressed == [:button_1, :button_2] &&
    @blinking == :none
end
blink_hours.postcondition = Proc.new { @blinking = :hours }

blink_minutes = DbcMethod.new(:blink_minutes)
blink_minutes.precondition = Proc.new do
  @watch.mode == :set_time &&
    @watch.last_buttons_pressed == [:button_1] &&
    @blinking == :hours
end
blink_minutes.postcondition = Proc.new { @blinking = :minutes }

stop_blinking = DbcMethod.new(:stop_blinking)
stop_blinking.precondition = Proc.new do
  @watch.time.is_new_time_committed &&
    @watch.last_buttons_pressed == [:button_1, :button_2] &&
    @blinking != :none
end
stop_blinking.postcondition = Proc.new { @blinking = :none }

refresh = DbcMethod.new(:refresh)
refresh.precondition = Proc.new { @watch.time.is_minutes_incremented }
refresh.postcondition = Proc.new { @is_refreshed = true }

display.add_dbc_methods(blink_hours, blink_minutes, stop_blinking, refresh)


# TwoBWatchTime methods
increment_minutes = DbcMethod.new(:increment_minutes)
increment_minutes.precondition = Proc.new do
  @watch.display.blinking == :minutes &&
    @watch.last_buttons_pressed == [:button_2]
end
increment_minutes.postcondition = Proc.new { @is_minutes_incremented = true }

commit_new_time = DbcMethod.new(:commit_new_time)
commit_new_time.precondition = Proc.new do
  @watch.last_buttons_pressed == [:button_1, :button_2] &&
    @watch.display.is_refreshed
end
commit_new_time.postcondition = Proc.new { @is_new_time_committed = true }

time.add_dbc_methods(increment_minutes, commit_new_time)


# TwoBWatchInput methods
press_button_1 = DbcMethod.new(:press_button_1)
press_button_1.precondition = Proc.new { @mode == :set_time }
press_button_1.postcondition = Proc.new do
  @last_buttons_pressed = [:button_1]
end

press_button_2 = DbcMethod.new(:press_button_2)
press_button_2.precondition = Proc.new { @mode == :set_time }
press_button_2.postcondition = Proc.new do
  @last_buttons_pressed = [:button_2]
end

press_buttons_1_and_2 = DbcMethod.new(:press_buttons_1_and_2)
press_buttons_1_and_2.precondition = Proc.new do
  @mode == :read_time || @display.is_refreshed
end
press_buttons_1_and_2.postcondition = Proc.new do
  @mode = case @mode
          when :read_time
            :set_time
          when :set_time
            :read_time
          end
  @last_buttons_pressed = [:button_1, :button_2]
end

watch.add_dbc_methods(press_button_1, press_button_2, press_buttons_1_and_2)


planner = Planner.new(:best_first_forward_search)
planner.initial_state.add(display, time, watch)
planner.goals = {
  'display' => Proc.new { @blinking == :none },
  'time' => Proc.new { @is_new_time_committed },
  'watch' => Proc.new { @mode == :read_time }
  # Incidentally, the condition on watch allows the planner to find the
  # solution if the previous-method-calls hack is turned off because the second
  # call to press_buttons_1_and_2 satisfies it and thus improves h(n).
}

planner.solve
puts prettify_plan(planner.plan, %w(Caller Method Receiver))
puts "# Goal Tests: #{planner.number_of_states_tested_for_goals}"

if planner.plan == :failure
  puts "Failed to satisfy the goals of the following objects:"
  puts planner.unsatisfied_objects_names
end
