-module(rudy).
-export([start/1, stop/0, start/2,request/1, init/2]).

start(Port) ->start(Port, 1).

start(Port, N)   ->
    register(rudy, spawn(fun() ->  init(Port, N) end)).
     
stop() ->
    exit(whereis(rudy), "time to die").



init(Port, N) ->
    Opt = [list, {active, false}, {reuseaddr, true}],
    case gen_tcp:listen(Port, Opt) of
        {ok, Listen} ->
           handlers(Listen, N),              %added
	       super(),
           gen_tcp:close(Listen),
           ok;
        {error, Error} ->
           error
    end.

super() ->
  receive
  stop ->ok
  end.
  
  
handlers(Listen, N) ->
    case N  of
      0  ->    ok;
      N  ->    
        spawn(fun() ->  
        handler(Listen, N)   end),  
        handlers(Listen, N-1)
    end.
  
  
  
handler(Listen, I) ->
    io:format("rudy: waiting for request~n", []),
    case gen_tcp:accept(Listen) of
        {ok, Client} ->
		    io:format("rudy ~w: received request~n", [I]),
            request(Client),         %added
            handler(Listen, I);      %added
        {error, Error} ->
            error
    end.



request(Client) ->
    io:format("rudy: reading request from ~w~n", [Client]),
    Recv = gen_tcp:recv(Client, 0),
    case Recv of
        {ok, Str} ->
	        io:format("rudy: parsing request~n", []),
            Request = http:parse_request(Str),      %added
            Response = reply(Request),    
            gen_tcp:send(Client, Response);
        {error, Error} ->
            io:format("rudy: error: ~w~n", [Error])
    end,
    gen_tcp:close(Client).


reply({{get, URI, _}, _, _}) ->
    timer:sleep(40),
    http:ok("
	<html><head><title>Rudy</title></head><body>This is a rudy server.<br/>" ++ URI ++ "</body></html>
	").