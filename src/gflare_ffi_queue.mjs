import { Ok, Error } from "./gleam.mjs";

export async function queue_send(queue, message) {
  try {
    await queue.send(message);
    return new Ok(undefined);
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function queue_send_batch(queue, messages) {
  try {
    await queue.sendBatch(messages);
    return new Ok(undefined);
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function queue_ack(message) {
  try {
    await message.ack();
    return new Ok(undefined);
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function queue_retry(message) {
  try {
    await message.retry();
    return new Ok(undefined);
  } catch (error) {
    return new Error(`${error}`);
  }
}

export function queue_message_id(message) {
  return message.id;
}

export function queue_message_timestamp(message) {
  return message.timestamp;
}

export function queue_message_body(message) {
  return message.body;
}

export function queue_message_attempts(message) {
  return message.attempts;
}
