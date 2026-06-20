-module(glare_ffi_r2).
-export([r2_get/2, r2_get_with_http_metadata/2, r2_put/4, r2_delete/2,
         r2_list/2, r2_head/2, r2_read_bytes/1, r2_read_text/1,
         r2_read_json/1, r2_create_multipart/3]).

r2_get(_Bucket, _Key) ->
    error({glare_error, "Not supported on Erlang target"}).

r2_get_with_http_metadata(_Bucket, _Key) ->
    error({glare_error, "Not supported on Erlang target"}).

r2_put(_Bucket, _Key, _Body, _Options) ->
    error({glare_error, "Not supported on Erlang target"}).

r2_delete(_Bucket, _Keys) ->
    error({glare_error, "Not supported on Erlang target"}).

r2_list(_Bucket, _Options) ->
    error({glare_error, "Not supported on Erlang target"}).

r2_head(_Bucket, _Key) ->
    error({glare_error, "Not supported on Erlang target"}).

r2_read_bytes(_Body) ->
    error({glare_error, "Not supported on Erlang target"}).

r2_read_text(_Body) ->
    error({glare_error, "Not supported on Erlang target"}).

r2_read_json(_Body) ->
    error({glare_error, "Not supported on Erlang target"}).

r2_create_multipart(_Bucket, _Key, _Options) ->
    error({glare_error, "Not supported on Erlang target"}).
