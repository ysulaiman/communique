# This is a (quick and dirty) example script that uses the library's classes to
# plan and generate a number of sequence diagrams (albeit in textual format).
# The example classes and use case are taken (with some modifications) from the
# senior project titled MeetingsMate.

require_relative '../lib/dbc_method'
require_relative '../lib/dbc_object'
require_relative '../lib/dbc_use_case'
require_relative '../lib/planner'

notification_instance = DbcObject.new('notification', :Notification, {
  :@meeting => nil
})

vote_instance = DbcObject.new('vote', :Vote, {
  :@is_closed => false
})

meeting_instance = DbcObject.new('meeting', :Meeting, {
  :@is_final_meeting_time_set => false,
  :@is_final_meeting_location_set => false,
  :@vote => vote_instance
})

user_profile_instance = DbcObject.new('user_profile', :UserProfile, {
  :@is_logged_in => true,
  :@notifications => []
})

log_in = DbcMethod.new(:log_in)
log_in.precondition = Proc.new do
  @dbc_class == :UserProfile &&
    !@is_logged_in
end
log_in.postcondition = Proc.new { @is_logged_in = true }

log_out = DbcMethod.new(:log_out)
log_out.precondition = Proc.new do
  @dbc_class == :UserProfile &&
    @is_logged_in
end
log_out.postcondition = Proc.new { @is_logged_in = false }

update_user_notifications = DbcMethod.new(:update_user_notifications)
update_user_notifications.precondition = Proc.new do
  @dbc_class == :UserProfile &&
    ! state.get_instance_of(:Notification).nil?
end
update_user_notifications.postcondition = Proc.new do
  @notifications << state.get_instance_of(:Notification)
end

user_profile_instance.add_dbc_methods(log_in, log_out,
                                      update_user_notifications)

add_notification = DbcMethod.new(:add_notification)
add_notification.precondition = Proc.new do
  @dbc_class == :Notification &&
    ! state.get_instance_of(:Vote).nil? &&
    state.get_instance_of(:Vote).is_closed
  # TODO: Solve the problem of "over-cloning" to be able to write the correct
  # condition, i.e.:
  # state.get_instance_of(:Meeting).vote.is_closed
end
add_notification.postcondition = Proc.new do
  @meeting = state.get_instance_of(:Meeting)
end

notification_instance.add_dbc_methods(add_notification)

close_vote = DbcMethod.new(:close_vote)
close_vote.precondition = Proc.new do
  @dbc_class == :Vote &&
    ! @is_closed &&
    state.get_instance_of(:Meeting).is_final_meeting_time_set &&
    state.get_instance_of(:Meeting).is_final_meeting_location_set
end
close_vote.postcondition = Proc.new { @is_closed = true }

vote_instance.add_dbc_methods(close_vote)

set_final_meeting_location = DbcMethod.new(:set_final_meeting_location)
set_final_meeting_location.precondition = Proc.new { true }
set_final_meeting_location.postcondition = Proc.new do
  @is_final_meeting_location_set = true
end

set_final_meeting_time = DbcMethod.new(:set_final_meeting_time)
set_final_meeting_time.precondition = Proc.new { true }
set_final_meeting_time.postcondition = Proc.new do
  @is_final_meeting_time_set = true
end

meeting_instance.add_dbc_methods(set_final_meeting_location,
                                 set_final_meeting_time)

finalize_meeting_use_case = DbcUseCase.new('Finalize Meeting')
finalize_meeting_use_case.dbc_instances << notification_instance <<
  vote_instance << meeting_instance << user_profile_instance
finalize_meeting_use_case.postconditions = {
  'meeting' => Proc.new { @is_final_meeting_time_set &&
    @is_final_meeting_location_set },
  'vote' => Proc.new { @is_closed },
  'notification' => Proc.new { ! @meeting.nil? },
  'user_profile' => Proc.new { @notifications.include? notification_instance }
}

planner = Planner.new
planner.set_up_initial_state(finalize_meeting_use_case)
planner.goals = finalize_meeting_use_case.postconditions

puts "Solving UC #{finalize_meeting_use_case.name} ..."
planner.solve
puts "Solution: #{planner.plan}\n"
