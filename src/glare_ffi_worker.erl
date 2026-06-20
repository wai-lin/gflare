-module(glare_ffi_worker).
-export([wait_until/2, pass_through_on_exception/1, new_response/1, set_body/2,
         set_header/3, response_json/2, response_bytes/2, response_empty/1,
         redirect/2, request_url/1, request_method/1, request_headers/1,
         request_body/1, request_text/1, request_json/1, request_array_buffer/1]).

wait_until(_Ctx, _Promise) ->
    error({glare_error, "Not supported on Erlang target"}).

pass_through_on_exception(_Ctx) ->
    error({glare_error, "Not supported on Erlang target"}).

new_response(_Status) ->
    error({glare_error, "Not supported on Erlang target"}).

set_body(_Response, _Body) ->
    error({glare_error, "Not supported on Erlang target"}).

set_header(_Response, _Name, _Value) ->
    error({glare_error, "Not supported on Erlang target"}).

response_json(_Response, _Data) ->
    error({glare_error, "Not supported on Erlang target"}).

response_bytes(_Response, _Data) ->
    error({glare_error, "Not supported on Erlang target"}).

response_empty(_Status) ->
    error({glare_error, "Not supported on Erlang target"}).

redirect(_Url, _Status) ->
    error({glare_error, "Not supported on Erlang target"}).

request_url(_Request) ->
    error({glare_error, "Not supported on Erlang target"}).

request_method(_Request) ->
    error({glare_error, "Not supported on Erlang target"}).

request_headers(_Request) ->
    error({glare_error, "Not supported on Erlang target"}).

request_body(_Request) ->
    error({glare_error, "Not supported on Erlang target"}).

request_text(_Request) ->
    error({glare_error, "Not supported on Erlang target"}).

request_json(_Request) ->
    error({glare_error, "Not supported on Erlang target"}).

request_array_buffer(_Request) ->
    error({glare_error, "Not supported on Erlang target"}).
