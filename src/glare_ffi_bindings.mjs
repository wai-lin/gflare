import { Ok, Error } from "../gleam.mjs";

function cast_kv(raw) {
  if (raw && typeof raw.get === "function" && typeof raw.put === "function" && typeof raw.delete === "function" && typeof raw.list === "function") {
    return new Ok(raw);
  }
  return new Error("Not a KV namespace");
}

function cast_d1(raw) {
  if (raw && typeof raw.prepare === "function" && typeof raw.batch === "function" && typeof raw.exec === "function") {
    return new Ok(raw);
  }
  return new Error("Not a D1 database");
}

function cast_r2(raw) {
  if (raw && typeof raw.get === "function" && typeof raw.put === "function" && typeof raw.delete === "function" && typeof raw.list === "function") {
    return new Ok(raw);
  }
  return new Error("Not an R2 bucket");
}

function cast_do(raw) {
  if (raw && typeof raw.idFromName === "function" && typeof raw.get === "function") {
    return new Ok(raw);
  }
  return new Error("Not a Durable Object namespace");
}

function cast_queue(raw) {
  if (raw && typeof raw.send === "function" && typeof raw.sendBatch === "function") {
    return new Ok(raw);
  }
  return new Error("Not a Queue");
}

export function get_kv(env, name) {
  const raw = env[name];
  if (raw === undefined || raw === null) {
    return new Error(`KV binding "${name}" not found`);
  }
  return cast_kv(raw);
}

export function get_d1(env, name) {
  const raw = env[name];
  if (raw === undefined || raw === null) {
    return new Error(`D1 binding "${name}" not found`);
  }
  return cast_d1(raw);
}

export function get_r2(env, name) {
  const raw = env[name];
  if (raw === undefined || raw === null) {
    return new Error(`R2 binding "${name}" not found`);
  }
  return cast_r2(raw);
}

export function get_do_namespace(env, name) {
  const raw = env[name];
  if (raw === undefined || raw === null) {
    return new Error(`Durable Object binding "${name}" not found`);
  }
  return cast_do(raw);
}

export function get_queue_producer(env, name) {
  const raw = env[name];
  if (raw === undefined || raw === null) {
    return new Error(`Queue binding "${name}" not found`);
  }
  return cast_queue(raw);
}

export function get_var(env, name) {
  const raw = env[name];
  if (raw === undefined || raw === null) {
    return new Error(`Variable "${name}" not found`);
  }
  return new Ok(`${raw}`);
}

export function get_secret(env, name) {
  const raw = env[name];
  if (raw === undefined || raw === null) {
    return new Error(`Secret "${name}" not found`);
  }
  return new Ok(`${raw}`);
}
