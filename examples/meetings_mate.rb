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
  :@final_meeting_time => nil,
  :@final_meeting_location => nil,
  :@vote => vote_instance
})

user_profile_instance = DbcObject.new('user_profile', :UserProfile, {
  :@username => 'john',
  :@password => 'secret',
  :@is_logged_in => true,
  :@notifications => []
})

log_in = DbcMethod.new(:log_in)
log_in.parameters = {username: 'john', password: 'secret'}
log_in.precondition = Proc.new do
  @dbc_class == :UserProfile &&
    !@is_logged_in &&
    log_in.parameters[:username] == @username &&
    log_in.parameters[:password] == @password
end
log_in.postcondition = Proc.new { @is_logged_in = true }

log_out = DbcMethod.new(:log_out)
log_out.precondition = Proc.new do
  @dbc_class == :UserProfile &&
    @is_logged_in
end
log_out.postcondition = Proc.new { @is_logged_in = false }

update_user_notifications = DbcMethod.new(:update_user_notifications)
update_user_notifications.parameters = {notification: notification_instance}
update_user_notifications.precondition = Proc.new do
  @dbc_class == :UserProfile &&
    ! update_user_notifications.parameters[:notification].nil?
end
update_user_notifications.postcondition = Proc.new do
  @notifications << update_user_notifications.parameters[:notification]
end

user_profile_instance.add_dbc_methods(log_in, log_out, update_user_notifications)

add_notification = DbcMethod.new(:add_notification)
add_notification.parameters = {meeting: meeting_instance}
add_notification.precondition = Proc.new do
  @dbc_class == :Notification &&
    ! add_notification.parameters[:meeting].nil?
  # TODO: Change the way you use parameters in conditions.
  # Due to the closure nature of Ruby blocks, the following condition will
  # always refer to the objects defined in this file, never their clones that
  # are generated and modified during (deterministic) planning. Therefore, it
  # will always evaluate to false if the vote is initially open, the
  # add_notification will never be applicable, and the planner will fail.
    #add_notification.parameters[:meeting].vote.is_closed
end
add_notification.postcondition = Proc.new do @meeting =
  add_notification.parameters[:meeting] end

notification_instance.add_dbc_methods(add_notification)

close_vote = DbcMethod.new(:close_vote)
close_vote.precondition = Proc.new do
  @dbc_class == :Vote &&
    ! @is_closed
end
close_vote.postcondition = Proc.new { @is_closed = true }

vote_instance.add_dbc_methods(close_vote)

set_final_meeting_location = DbcMethod.new(:set_final_meeting_location)
set_final_meeting_location.parameters = {location: 'Gale Crater'}
set_final_meeting_location.precondition = Proc.new do
  @dbc_class == :Meeting &&
    ! set_final_meeting_location.parameters[:location].nil?
end
set_final_meeting_location.postcondition = Proc.new do
  @final_meeting_location = set_final_meeting_location.parameters[:location]
end

set_final_meeting_time = DbcMethod.new(:set_final_meeting_time)
set_final_meeting_time.parameters = {time: Time.now}
set_final_meeting_time.precondition = Proc.new do
  @dbc_class == :Meeting &&
    ! set_final_meeting_time.parameters[:time].nil?
end
set_final_meeting_time.postcondition = Proc.new do
  @final_meeting_time = set_final_meeting_time.parameters[:time]
end

meeting_instance.add_dbc_methods(set_final_meeting_location, set_final_meeting_time)

finalize_meeting_use_case = DbcUseCase.new('Finalize Meeting')
finalize_meeting_use_case.dbc_instances << notification_instance << vote_instance << meeting_instance << user_profile_instance
finalize_meeting_use_case.postconditions = {
  'meeting' => Proc.new { ! @final_meeting_time.nil? && ! @final_meeting_location.nil? },
  'vote' => Proc.new { @is_closed },
  'notification' => Proc.new { ! @meeting.nil? },
  'user_profile' => Proc.new { @notifications.include? notification_instance }
}

planner = Planner.new
planner.set_up_initial_state(finalize_meeting_use_case)
planner.goals = finalize_meeting_use_case.postconditions

puts "Solving UC #{finalize_meeting_use_case.name} ..."
planner.solve
puts "Solution: #{planner.plan}\n\n"
