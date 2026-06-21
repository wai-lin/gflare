import { Ok, Error } from "./gleam.mjs";

export function do_id_from_name(namespace, name) {
  return namespace.idFromName(name);
}

export function do_id_from_string(namespace, id) {
  return namespace.idFromString(id);
}

export function do_get_stub(namespace, id) {
  return namespace.get(id);
}

export async function do_fetch(stub, path, options) {
  try {
    const opts = { method: "POST" };
    if (options && options.method) opts.method = options.method;
    if (options && options.body) opts.body = JSON.stringify(options.body);
    const response = await new Request(path, opts);
    const result = await stub.fetch(response);
    const data = await result.json();
    return new Ok(data);
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function do_get(stub) {
  try {
    const response = await new Request("/", { method: "GET" });
    const result = await stub.fetch(response);
    const data = await result.json();
    return new Ok(data);
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function do_set(stub, key, value) {
  try {
    const response = new Request("/", {
      method: "POST",
      body: JSON.stringify({ action: "set", key, value }),
    });
    await stub.fetch(response);
    return new Ok(undefined);
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function do_delete(stub, key) {
  try {
    const response = new Request("/", {
      method: "POST",
      body: JSON.stringify({ action: "delete", key }),
    });
    await stub.fetch(response);
    return new Ok(undefined);
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function do_get_alarm(stub) {
  try {
    const response = await new Request("/", { method: "GET", headers: { "x-action": "get-alarm" } });
    const result = await stub.fetch(response);
    const data = await result.json();
    return new Ok(data);
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function do_set_alarm(stub, timestamp) {
  try {
    const response = new Request("/", {
      method: "POST",
      body: JSON.stringify({ action: "set-alarm", timestamp }),
    });
    await stub.fetch(response);
    return new Ok(undefined);
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function do_delete_alarm(stub) {
  try {
    const response = new Request("/", {
      method: "POST",
      body: JSON.stringify({ action: "delete-alarm" }),
    });
    await stub.fetch(response);
    return new Ok(undefined);
  } catch (error) {
    return new Error(`${error}`);
  }
}
