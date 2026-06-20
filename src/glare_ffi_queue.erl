-module(glare_ffi_queue).
-export([queue_send/2, queue_send_batch/2, queue_ack/1, queue_retry/1,
         queue_message_id/1, queue_message_timestamp/1, queue_message_body/1,
         queue_message_attempts/1]).

queue_send(_Queue, _Message) ->
    error({glare_error, "Not supported on Erlang target"}).

queue_send_batch(_Queue, _Messages) ->
    error({glare_error, "Not supported on Erlang target"}).

queue_ack(_Message) ->
    error({glare_error, "Not supported on Erlang target"}).

queue_retry(_Message) ->
    error({glare_error, "Not supported on Erlang target"}).

queue_message_id(_Message) ->
    error({glare_error, "Not supported on Erlang target"}).

queue_message_timestamp(_Message) ->
    error({glare_error, "Not supported on Erlang target"}).

queue_message_body(_Message) ->
    error({glare_error, "Not supported on Erlang target"}).

queue_message_attempts(_Message) ->
    error({glare_error, "Not supported on Erlang target"}).
