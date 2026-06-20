import { Ok, Error } from "../gleam.mjs";

export async function r2_get(bucket, key) {
  try {
    const object = await bucket.get(key);
    if (object === null) {
      return new Error("Object not found");
    }
    return new Ok(object);
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function r2_get_with_http_metadata(bucket, key) {
  try {
    const object = await bucket.get(key, { onlyMetadata: true });
    if (object === null) {
      return new Error("Object not found");
    }
    return new Ok({
      key: object.key,
      version: object.version,
      size: object.size,
      etag: object.httpEtag,
      http_metadata: object.httpMetadata,
      custom_metadata: object.customMetadata,
      uploaded: object.uploaded,
    });
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function r2_put(bucket, key, body, options) {
  try {
    const opts = {};
    if (options.http_metadata) opts.httpMetadata = options.http_metadata;
    if (options.custom_metadata) opts.customMetadata = options.custom_metadata;
    const result = await bucket.put(key, body, opts);
    return new Ok({
      key: result.key,
      version: result.version,
      size: result.size,
      etag: result.httpEtag,
      uploaded: result.uploaded,
    });
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function r2_delete(bucket, keys) {
  try {
    await bucket.delete(keys);
    return new Ok(undefined);
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function r2_list(bucket, options) {
  try {
    const opts = {};
    if (options.prefix !== null && options.prefix !== undefined) opts.prefix = options.prefix;
    if (options.cursor !== null && options.cursor !== undefined) opts.cursor = options.cursor;
    if (options.delimiter !== null && options.delimiter !== undefined) opts.delimiter = options.delimiter;
    if (options.limit !== null && options.limit !== undefined) opts.limit = options.limit;
    if (options.include !== null && options.include !== undefined) opts.include = options.include;
    const result = await bucket.list(opts);
    return new Ok({
      objects: result.objects.map(obj => ({
        key: obj.key,
        version: obj.version,
        size: obj.size,
        etag: obj.httpEtag,
        uploaded: obj.uploaded,
      })),
      truncated: result.truncated,
      cursor: result.cursor,
      delimited_prefixes: result.delimitedPrefixes,
    });
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function r2_head(bucket, key) {
  try {
    const object = await bucket.head(key);
    if (object === null) {
      return new Error("Object not found");
    }
    return new Ok({
      key: object.key,
      version: object.version,
      size: object.size,
      etag: object.httpEtag,
      http_metadata: object.httpMetadata,
      custom_metadata: object.customMetadata,
      uploaded: object.uploaded,
    });
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function r2_read_bytes(body) {
  try {
    const buffer = await body.arrayBuffer();
    return new Ok(new Uint8Array(buffer));
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function r2_read_text(body) {
  try {
    const text = await body.text();
    return new Ok(text);
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function r2_read_json(body) {
  try {
    const data = await body.json();
    return new Ok(data);
  } catch (error) {
    return new Error(`${error}`);
  }
}

export async function r2_create_multipart(bucket, key, options) {
  try {
    const opts = {};
    if (options.http_metadata) opts.httpMetadata = options.http_metadata;
    if (options.custom_metadata) opts.customMetadata = options.custom_metadata;
    const result = await bucket.createMultipartUpload(key, opts);
    return new Ok(result);
  } catch (error) {
    return new Error(`${error}`);
  }
}
