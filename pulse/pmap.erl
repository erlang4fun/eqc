-module(pmap).

-include_lib("eqc/include/eqc.hrl").
-include_lib("pulse/include/pulse.hrl"). %% for ?PULSE

-compile(export_all).

%% correct one
pmap(Fun, List) ->
    Parent = self(),
    Pids = [spawn(fun() -> Parent ! {self(), Fun(X)} end) || X <- List],
    [receive {Pid, Res} -> Res end || Pid <- Pids].

pmap_demo() ->
    Fun = fun(X) -> X + 1 end,
    pmap(Fun, lists:seq(1, 10)).

prop_pmap() ->
    Fun = fun(X) -> X + 1 end,
    ?FORALL(L, list(int()),
	    pmap(Fun, L) == lists:map(Fun, L)).

%% race condition
pmap_race_condition(Fun, List) ->
    Parent = self(),
    [spawn(fun() -> Parent ! Fun(X) end) || X <- List],
    [receive Res -> Res end || _ <- List].

pmap_race_condition_demo() ->
    Fun = fun(X) -> X + 1 end,
    pmap_race_condition(Fun, lists:seq(1, 10)).
    
prop_pmap_race_condition() ->
%%    Fun = fun(X) -> X + 1 end,
    ?FORALL(L, list(int()),
	    begin
		Res = lists:map(fun plus/1, L),
		PRes = pmap_race_condition(fun plus/1, L),
		?WHENFAIL(
		   io:format("~p /= ~p~n", [Res, PRes]),
		   Res == PRes)
	    end).

plus(X) -> X + 1.

%% now use ?PULSE macro
prop_pmap_race_condition_pulse() ->
    ?FORALL({F, L},
	    {function1(nat()), list(int())},
	    begin
		Res = lists:map(F, L),
		?PULSE(PRes, pmap_race_condition(F, L),
		       ?WHENFAIL(
			  io:format("~p /= ~p~n", [Res, PRes]),
			  Res == PRes))
	    end).





		  
