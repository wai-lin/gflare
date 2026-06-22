import { List, NonEmpty, Empty } from "./gleam.mjs";

// Parse URL path into segments
export function parse_path(url) {
  try {
    const url_obj = new URL(url);
    const path = url_obj.pathname;
    // Remove leading slash and split
    const segments = path.split("/").filter(s => s.length > 0);
    return segments;
  } catch {
    // Fallback for invalid URLs
    const segments = url.split("/").filter(s => s.length > 0);
    return segments;
  }
}

// Get query parameters as list of key-value pairs
export function parse_query_params(url) {
  try {
    const url_obj = new URL(url);
    const params = [];
    for (const [key, value] of url_obj.searchParams) {
      params.push([key, value]);
    }
    return params;
  } catch {
    return [];
  }
}

// Get the path from a URL
export function get_path(url) {
  try {
    const url_obj = new URL(url);
    return url_obj.pathname;
  } catch {
    const idx = url.indexOf("?");
    if (idx !== -1) {
      return url.substring(0, idx);
    }
    return url;
  }
}

// Check if path starts with prefix
export function path_starts_with(path, prefix) {
  return path.startsWith(prefix);
}

// Remove prefix from path
export function remove_prefix(path, prefix) {
  if (path.startsWith(prefix)) {
    return path.substring(prefix.length);
  }
  return path;
}
