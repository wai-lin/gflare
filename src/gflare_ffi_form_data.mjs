import { Ok, Error, List } from "./gleam.mjs";

class GleamText {
  constructor(value) {
    this.Text = value;
  }
}

class GleamFile {
  constructor(filename, content_type, data) {
    this.File = [filename, content_type, data];
  }
}

function to_form_field(val) {
  if (typeof val === "string") return new GleamText(val);
  return new GleamFile(
    val.name || null,
    val.type || null,
    new Uint8Array(val),
  );
}

function entries_to_list(entries) {
  return List.fromArray(
    entries.map(([key, val]) => [key, to_form_field(val)]),
  );
}

export async function parse_form_data(request) {
  try {
    const fd = await request.formData();
    const entries = [];
    for (const [key, val] of fd.entries()) {
      entries.push([key, to_form_field(val)]);
    }
    return new Ok({ FormData: List.fromArray(entries) });
  } catch (e) {
    return new Error(`${e}`);
  }
}

export function form_data_get(fd, name) {
  const val = fd.get(name);
  if (val === null || val === undefined) return undefined;
  return to_form_field(val);
}

export function form_data_get_all(fd, name) {
  const vals = fd.getAll(name);
  return List.fromArray(vals.map(to_form_field));
}

export function form_data_entries(fd) {
  return entries_to_list(fd.entries());
}
