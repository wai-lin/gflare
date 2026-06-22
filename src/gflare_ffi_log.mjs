export function console_log(message) {
  console.log(message);
}

export function console_warn(message) {
  console.warn(message);
}

export function console_error(message) {
  console.error(message);
}

export function generate_request_id() {
  return crypto.randomUUID();
}

export function get_timestamp() {
  return new Date().toISOString();
}

export function get_current_time() {
  return performance.now();
}

export function response_status(response) {
  return response.status;
}

export function response_body_text(response) {
  // Note: This is a simplified version. In reality, reading body is async.
  // For middleware logging, we'll use a different approach.
  return undefined;
}
