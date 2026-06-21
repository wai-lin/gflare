import { Ok, Error } from "./gleam.mjs";

export async function kv_get(namespace, key, options) {
  try {
    const opts = {};
    if (options.type_) opts.type = options.type_;
    if (options.cache_ttl !== null && options.cache_ttl !== undefined) opts.cacheTtl = options.cache_ttl;
    const value = await namespace.get(key, opts);
    return value === null ? new Error("Key not found") : new Ok(value);
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function kv_get_with_metadata(namespace, key, options) {
  try {
    const opts = {};
    if (options.type_) opts.type = options.type_;
    if (options.cache_ttl !== null && options.cache_ttl !== undefined) opts.cacheTtl = options.cache_ttl;
    const result = await namespace.getWithMetadata(key, opts);
    return new Ok({ value: result.value, metadata: result.metadata });
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function kv_put(namespace, key, value, options) {
  try {
    const opts = {};
    if (options.expiration !== null && options.expiration !== undefined) opts.expiration = options.expiration;
    if (options.expiration_ttl !== null && options.expiration_ttl !== undefined) opts.expirationTtl = options.expiration_ttl;
    await namespace.put(key, value, opts);
    return new Ok(undefined);
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function kv_delete(namespace, key) {
  try {
    await namespace.delete(key);
    return new Ok(undefined);
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function kv_list(namespace, options) {
  try {
    const opts = {};
    if (options.prefix !== null && options.prefix !== undefined) opts.prefix = options.prefix;
    if (options.cursor !== null && options.cursor !== undefined) opts.cursor = options.cursor;
    if (options.limit !== null && options.limit !== undefined) opts.limit = options.limit;
    if (options.reverse !== null && options.reverse !== undefined) opts.reverse = options.reverse;
    const result = await namespace.list(opts);
    return new Ok({
      keys: result.keys.map(k => ({ name: k.name, metadata: k.metadata, expiration: k.expiration })),
      list_complete: result.list_complete,
      cursor: result.cursor,
    });
  } catch (error) {
    return new Error(`${error}`);
  }
}
