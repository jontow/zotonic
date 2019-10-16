%%%-------------------------------------------------------------------
%%% @author Blaise
%%% @doc
%% @copyright 2017
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%	 http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%%
%% usage zotonic generate-edoc
%%
%%% @end
%%% Created : 13. Dec 2017 6:47 PM
%%%-------------------------------------------------------------------
-module(zotonic_cmd_addsite).
-author("Blaise").

%% API
-export([run/1]).

-define(SKEL, blog).
-define(ADMINPASSWORD, admin).

usage() ->
    io:format("Usage: zotonic addsite [options] <site_name> ~n~n"),
    io:format(" -s <skel>     Skeleton site (one of 'blog', 'basesite', 'empty', 'nodb'; default: ~s~n", [?SKEL]),
    io:format(" -H <host>     Site's hostname (default: <site_name.test>) ~n"),
    io:format(" -L            Create the site in the current directory and symlink it into ~n"),
    io:format(" -g <remote>   Create a git repository in the site and push it to the given remote ~n"),
    io:format(" -h <host>     Database host (default: ~s) ~n", [ z_config:get(dbhost) ]),
    io:format(" -p <port>     Database port (default: ~p) ~n", [ z_config:get(dbport) ]),
    io:format(" -u <user>     Database user (default: ~s) ~n", [ z_config:get(dbuser) ]),
    io:format(" -P <pass>     Database password (default: ~s) ~n", [ z_config:get(dbpassword) ]),
    io:format(" -d <name>     Database name (default: ~s) ~n", [ z_config:get(dbdatabase) ]),
    io:format(" -n <schema>   Database schema (defaults to <site_name>) ~n"),
    io:format(" -a <pass>     Admin password (default: ~s) ~n~n", [ ?ADMINPASSWORD ]).

run(Args) ->
    case zotonic_command:get_target_node() of
        {ok, Target} ->
            run_target(Target, Args);
        {error, _} = Error ->
            zotonic_command:format_error(Error)
    end.

run_target(Target, Args) ->
    ZotonicConfigFiles = zotonic_launcher_config:zotonic_config_files(Target),
    case zotonic_launcher_config:read_configs(ZotonicConfigFiles) of
        {ok, Cfg} ->
            zotonic_launcher_config:load_configs(Cfg),
            run_parse_args(Target, Args);
        {error, _} = ZError ->
            zotonic_command:format_error(ZError)
    end.

run_parse_args(_Target, []) ->
    usage();
run_parse_args(Target, Args) ->
    case parse(Args) of
        {error, Arg} ->
            io:format(standard_error, "Unknown argument ~p~n~n", [ Arg ]),
            usage(),
            halt(1);
        {Options, [ Sitename ]} ->
            io:format("~p~n", [Options]),
            erlang:error(not_implemented);
        {_Options, []} ->
            io:format(standard_error, "Missing site name.~n~n", []),
            usage(),
            halt(1);
        {_Options, _} ->
            io:format(standard_error, "More than one site name.~n~n", []),
            usage(),
            halt(1)
    end.

-spec parse( list() ) -> {map(), list()}.
parse(Args) when is_list(Args) ->
    parse_args(Args, #{}).

parse_args([ "-s", Skel | Args ], Acc) ->
    parse_args(Args, Acc#{ skel => Skel });
parse_args([ "-H", Host | Args ], Acc) ->
    parse_args(Args, Acc#{ host => Host });
parse_args([ "-L" | Args ], Acc) ->
    parse_args(Args, Acc#{ symlink => true });
parse_args([ "-g", Remote | Args ], Acc) ->
    parse_args(Args, Acc#{ remote => Remote });
parse_args([ "-h", Host | Args ], Acc) ->
    parse_args(Args, Acc#{ dbhost => Host });
parse_args([ "-p", Host | Args ], Acc) ->
    parse_args(Args, Acc#{ dbhost => Host });
parse_args([ "-u", User | Args ], Acc) ->
    parse_args(Args, Acc#{ dbuser => User });
parse_args([ "-P", Pw | Args ], Acc) ->
    parse_args(Args, Acc#{ dbpassword => Pw });
parse_args([ "-d", Database | Args ], Acc) ->
    parse_args(Args, Acc#{ dbdatabase => Database });
parse_args([ "-n", Schema | Args ], Acc) ->
    parse_args(Args, Acc#{ dbschema => Schema });
parse_args([ "-a", Pw | Args ], Acc) ->
    parse_args(Args, Acc#{ admin_password => Pw });
parse_args([ "-" ++ _ = Arg | _ ], _Acc) ->
    {error, Arg};
parse_args(Rest, Acc) ->
    {Acc, Rest}.
