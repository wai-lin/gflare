-module(glare_ffi_d1).
-export([d1_prepare/2, d1_bind/2, d1_run/1, d1_first/1, d1_all/1,
         d1_batch/2, d1_exec/2, d1_dump/1, d1_with_session/2]).

d1_prepare(_Db, _Query) ->
    error({glare_error, "Not supported on Erlang target"}).

d1_bind(_Statement, _Values) ->
    error({glare_error, "Not supported on Erlang target"}).

d1_run(_Statement) ->
    error({glare_error, "Not supported on Erlang target"}).

d1_first(_Statement) ->
    error({glare_error, "Not supported on Erlang target"}).

d1_all(_Statement) ->
    error({glare_error, "Not supported on Erlang target"}).

d1_batch(_Db, _Statements) ->
    error({glare_error, "Not supported on Erlang target"}).

d1_exec(_Db, _Query) ->
    error({glare_error, "Not supported on Erlang target"}).

d1_dump(_Db) ->
    error({glare_error, "Not supported on Erlang target"}).

d1_with_session(_Db, _Session) ->
    error({glare_error, "Not supported on Erlang target"}).
