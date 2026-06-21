import { Ok, Error, toList } from "./gleam.mjs";

function encodeValue(value) {
  if (value === "Null") {
    return { type: "null" };
  }
  const tag = value.constructor?.name;
  switch (tag) {
    case "Text":
      return { type: "text", value: value[0] };
    case "Integer":
      return { type: "integer", value: String(value[0]) };
    case "Float":
      return { type: "float", value: String(value[0]) };
    case "Blob":
      return { type: "blob", base64: btoa(String.fromCharCode(...value[0])) };
    default:
      return { type: "null" };
  }
}

function decodeValue(col) {
  if (col === null || col === undefined) {
    return "Null";
  }
  if (typeof col === "string") {
    return { constructor: { name: "Text" }, 0: col };
  }
  if (typeof col === "number") {
    if (Number.isInteger(col)) {
      return { constructor: { name: "Integer" }, 0: col };
    }
    return { constructor: { name: "Float" }, 0: col };
  }
  if (typeof col === "bigint") {
    return { constructor: { name: "Integer" }, 0: Number(col) };
  }
  if (col.type === "blob" && col.base64) {
    const binary = atob(col.base64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i);
    }
    return { constructor: { name: "Blob" }, 0: bytes };
  }
  return "Null";
}

function decodeRow(row, columns) {
  const values = [];
  for (let i = 0; i < columns.length; i++) {
    values.push(decodeValue(row[i]));
  }
  return {
    constructor: { name: "Row" },
    0: toList(columns),
    1: toList(values),
  };
}

function decodeResult(data) {
  const results = data.results || [];
  const executeResult = results.find(
    (r) => r.type === "ok" && r.response?.type === "execute",
  );
  if (!executeResult) {
    return new Error("No execute result found");
  }
  const result = executeResult.response.result;
  const columns = (result.cols || []).map((c) => c.name);
  const rows = (result.rows || []).map((row) => decodeRow(row, columns));
  const lastInsertRowid = result.last_insert_rowid
    ? Number(result.last_insert_rowid)
    : null;
  return new Ok({
    constructor: { name: "ExecuteResult" },
    0: toList(rows),
    1: toList(columns),
    2: result.affected_row_count || 0,
    3: lastInsertRowid,
  });
}

export function turso_connect(url, auth_token) {
  return { constructor: { name: "Config" }, 0: url, 1: auth_token };
}

export async function turso_execute(config, sql, argsList) {
  try {
    const args = [];
    let current = argsList;
    while (current.constructor?.name === "NonEmpty") {
      args.push(encodeValue(current[0]));
      current = current[1];
    }
    const response = await fetch(`${config[0]}/v2/pipeline`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${config[1]}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        requests: [{ type: "execute", stmt: { sql, args } }, { type: "close" }],
      }),
    });
    const data = await response.json();
    return decodeResult(data);
  } catch (error) {
    return new Error(`Turso request failed: ${error.message}`);
  }
}

export async function turso_batch(config, statementsList, mode) {
  try {
    const statements = [];
    let current = statementsList;
    while (current.constructor?.name === "NonEmpty") {
      const pair = current[0];
      const sql = pair[0];
      const argsList = pair[1];
      const args = [];
      let argCurrent = argsList;
      while (argCurrent.constructor?.name === "NonEmpty") {
        args.push(encodeValue(argCurrent[0]));
        argCurrent = argCurrent[1];
      }
      statements.push({ type: "execute", stmt: { sql, args } });
      current = current[1];
    }
    statements.push({ type: "close" });
    const modeStr = mode === "Read" ? "read" : "write";
    const response = await fetch(`${config[0]}/v2/pipeline`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${config[1]}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ requests: statements }),
    });
    const data = await response.json();
    const results = [];
    for (const r of data.results || []) {
      if (r.type === "ok" && r.response?.type === "execute") {
        const result = r.response.result;
        const columns = (result.cols || []).map((c) => c.name);
        const rows = (result.rows || []).map((row) => decodeRow(row, columns));
        const lastInsertRowid = result.last_insert_rowid
          ? Number(result.last_insert_rowid)
          : null;
        results.push({
          constructor: { name: "ExecuteResult" },
          0: toList(rows),
          1: toList(columns),
          2: result.affected_row_count || 0,
          3: lastInsertRowid,
        });
      }
    }
    return new Ok(toList(results));
  } catch (error) {
    return new Error(`Turso batch failed: ${error.message}`);
  }
}

export async function turso_transaction(config, statementsList) {
  try {
    const statements = [];
    let current = statementsList;
    while (current.constructor?.name === "NonEmpty") {
      const pair = current[0];
      const sql = pair[0];
      const argsList = pair[1];
      const args = [];
      let argCurrent = argsList;
      while (argCurrent.constructor?.name === "NonEmpty") {
        args.push(encodeValue(argCurrent[0]));
        argCurrent = argCurrent[1];
      }
      statements.push({ type: "execute", stmt: { sql, args } });
      current = current[1];
    }
    statements.push({ type: "close" });
    const response = await fetch(`${config[0]}/v2/pipeline`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${config[1]}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ requests: statements }),
    });
    const data = await response.json();
    const hasError = data.results?.some((r) => r.type === "error");
    if (hasError) {
      return new Error("Transaction failed");
    }
    const results = [];
    for (const r of data.results || []) {
      if (r.type === "ok" && r.response?.type === "execute") {
        const result = r.response.result;
        const columns = (result.cols || []).map((c) => c.name);
        const rows = (result.rows || []).map((row) => decodeRow(row, columns));
        const lastInsertRowid = result.last_insert_rowid
          ? Number(result.last_insert_rowid)
          : null;
        results.push({
          constructor: { name: "ExecuteResult" },
          0: toList(rows),
          1: toList(columns),
          2: result.affected_row_count || 0,
          3: lastInsertRowid,
        });
      }
    }
    return new Ok(toList(results));
  } catch (error) {
    return new Error(`Turso transaction failed: ${error.message}`);
  }
}
