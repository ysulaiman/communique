# The purpose of this experiment is to show that the planner is capable of
# generating a sequence diagram similar to one in a software engineering book.
# The sequence diagram in question is the one for the AnnounceTournament use
# case (tournament creation workflow) of the ARENA system depicted in Figure
# 5-26 of Object-Oriented Software Engineering Using UML, Patterns, and Java by
# Bernd Bruegge and Allen H. Dutoit. Some of the relevant classes are depicted
# in Figures 5-29 and 5-31.

require_relative 'experiment_helpers'


arena = DbcObject.new('arena', :Arena, {
  :@is_max_tournament_checked => false
})

league = DbcObject.new('league', :League, {
  :@tournaments => []
})

tournament = DbcObject.new('tournament', :Tournament, {
  :@league => league
})
tournament.dead = true

league.tournaments.push(tournament)

tournament_form = DbcObject.new('tournament_form', :TournamentForm, {
  :@is_name_set => false,
  :@is_max_players_set => false,
  :@is_committed => false,
  :@tournament => nil,
  :@announce_tournament_control => nil
})
tournament_form.boundary_object = true

announce_tournament_control =
  DbcObject.new('announce_tournament_control', :AnnounceTournamentControl, {
    :@is_create_tournament_request_recieved => false,
    :@arena => arena,
    :@tournament_form => tournament_form,
    :@league => league
  })
announce_tournament_control.dead = true

tournament_form.announce_tournament_control = announce_tournament_control


# TournamentForm methods.
new_tournament = DbcMethod.new(:new_tournament)
new_tournament.precondition = Proc.new { true }
new_tournament.postcondition = Proc.new {} # ?
new_tournament.dependencies.push(announce_tournament_control.dbc_name)

set_name = DbcMethod.new(:set_name)
set_name.precondition = Proc.new do
  state.get_instance_of(:Arena).is_max_tournament_checked
end
set_name.postcondition = Proc.new { @is_name_set = true }

set_max_players = DbcMethod.new(:set_max_players)
set_max_players.precondition = Proc.new { @is_name_set }
set_max_players.postcondition = Proc.new { @is_max_players_set = true }

commit = DbcMethod.new(:commit)
commit.precondition = Proc.new { @is_name_set && @is_max_players_set }
commit.postcondition = Proc.new { @is_committed = true }

tournament_form.add_dbc_methods(new_tournament, set_name, set_max_players, commit)


#AnnounceTournamentControl methods.
control_create_tournament = DbcMethod.new(:create_tournament)
control_create_tournament.precondition = Proc.new do
  self.tournament_form.is_committed
end
control_create_tournament.postcondition = Proc.new do
  @is_create_tournament_request_recieved = true
end

announce_tournament_control.add_dbc_methods(control_create_tournament)


# Arena methods.
check_max_tournament = DbcMethod.new(:check_max_tournament)
check_max_tournament.precondition = Proc.new do
  ! state.get_instance_of(:AnnounceTournamentControl).dead?
end
check_max_tournament.postcondition = Proc.new do
  @is_max_tournament_checked = true
end

arena.add_dbc_methods(check_max_tournament)


# League methods.
# As far as the previously-called-methods hack is concerned, the
# control_create_tournament and league_create_tournament DbcMethods are the
# same method if they have the same name (:create_tournament). This will cause
# :failure. Until the hack is fixed/removed, the workaround is to use different
# names for the methods.
# TODO: Rename league_create_tournament after fixing/removed the
# previously-called-methods hack.
league_create_tournament = DbcMethod.new(:league_create_tournament)
league_create_tournament.precondition = Proc.new do
  state.get_instance_of(:AnnounceTournamentControl).is_create_tournament_request_recieved
end
league_create_tournament.postcondition = Proc.new { }
league_create_tournament.dependencies.push(tournament.dbc_name)

league.add_dbc_methods(league_create_tournament)


if false  # Don't set method parameters if you wanna output a prettified plan.
  new_tournament.parameters = {league: :l}
  set_name.parameters = {name: :n}
  set_max_players.parameters = {maxp: :m}
  control_create_tournament.parameters = {name: :n, maxp: :m}
  league_create_tournament.parameters = {name: :n, maxp: :m}
end


announce_tournament_use_case = DbcUseCase.new('Announce Tournament')
announce_tournament_use_case.dbc_instances << tournament_form <<
  announce_tournament_control << arena << league << tournament
announce_tournament_use_case.postconditions = {
  'tournament' => Proc.new { ! dead? }
}

solve_and_report(announce_tournament_use_case)
