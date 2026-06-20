-module(glare_ffi_do).
-export([do_id_from_name/2, do_id_from_string/2, do_get_stub/2, do_fetch/3,
         do_get/1, do_set/3, do_delete/2, do_get_alarm/1, do_set_alarm/2,
         do_delete_alarm/1]).

do_id_from_name(_Namespace, _Name) ->
    error({glare_error, "Not supported on Erlang target"}).

do_id_from_string(_Namespace, _Id) ->
    error({glare_error, "Not supported on Erlang target"}).

do_get_stub(_Namespace, _Id) ->
    error({glare_error, "Not supported on Erlang target"}).

do_fetch(_Stub, _Path, _Options) ->
    error({glare_error, "Not supported on Erlang target"}).

do_get(_Stub) ->
    error({glare_error, "Not supported on Erlang target"}).

do_set(_Stub, _Key, _Value) ->
    error({glare_error, "Not supported on Erlang target"}).

do_delete(_Stub, _Key) ->
    error({glare_error, "Not supported on Erlang target"}).

do_get_alarm(_Stub) ->
    error({glare_error, "Not supported on Erlang target"}).

do_set_alarm(_Stub, _Timestamp) ->
    error({glare_error, "Not supported on Erlang target"}).

do_delete_alarm(_Stub) ->
    error({glare_error, "Not supported on Erlang target"}).
