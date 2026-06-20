-module(glare_ffi_kv).
-export([kv_get/3, kv_get_with_metadata/3, kv_put/4, kv_delete/2, kv_list/2]).

kv_get(_Namespace, _Key, _Options) ->
    error({glare_error, "Not supported on Erlang target"}).

kv_get_with_metadata(_Namespace, _Key, _Options) ->
    error({glare_error, "Not supported on Erlang target"}).

kv_put(_Namespace, _Key, _Value, _Options) ->
    error({glare_error, "Not supported on Erlang target"}).

kv_delete(_Namespace, _Key) ->
    error({glare_error, "Not supported on Erlang target"}).

kv_list(_Namespace, _Options) ->
    error({glare_error, "Not supported on Erlang target"}).
