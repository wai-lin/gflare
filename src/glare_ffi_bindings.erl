-module(glare_ffi_bindings).
-export([get_kv/2, get_d1/2, get_r2/2, get_do_namespace/2,
         get_queue_producer/2, get_var/2, get_secret/2]).

get_kv(_Env, _Name) ->
    error({glare_error, "Not supported on Erlang target"}).

get_d1(_Env, _Name) ->
    error({glare_error, "Not supported on Erlang target"}).

get_r2(_Env, _Name) ->
    error({glare_error, "Not supported on Erlang target"}).

get_do_namespace(_Env, _Name) ->
    error({glare_error, "Not supported on Erlang target"}).

get_queue_producer(_Env, _Name) ->
    error({glare_error, "Not supported on Erlang target"}).

get_var(_Env, _Name) ->
    error({glare_error, "Not supported on Erlang target"}).

get_secret(_Env, _Name) ->
    error({glare_error, "Not supported on Erlang target"}).
