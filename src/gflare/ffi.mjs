export function generate_uuid() {
  return crypto.randomUUID();
}

export function get_iso_timestamp() {
  return new Date().toISOString();
}

export function get_iso_date() {
  return new Date().toISOString().split("T")[0];
}
