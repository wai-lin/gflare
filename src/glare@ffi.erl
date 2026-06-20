-module(glare@ffi).
-export([generate_uuid/0]).

generate_uuid() ->
    error({glare_error, "Not supported on Erlang target"}).
