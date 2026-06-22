# Troubleshooting

Common issues and how to fix them.

## Build Errors

### "Cannot find module" error

```
Error [ERR_MODULE_NOT_FOUND]: Cannot find module './gleam.mjs'
```

**Fix:** Run `gleam build` before running other commands:

```bash
gleam build
gleam run -m gflare -- dev
```

### "Unknown type" error

```
error: Unknown type
  ┌─ src/my_worker.gleam:5:1
```

**Fix:** Check your imports. You might be using a type that isn't imported:

```gleam
// Wrong
import gflare/bindings

// Right
import gflare/bindings.{type Env}
```

### "Type mismatch" error

```
error: Type mismatch
  Expected type: String
  Found type: Int
```

**Fix:** Check that you're passing the correct types. Gleam is strict about types:

```gleam
// Wrong — io.println expects String
io.println(42)

// Right — convert Int to String first
io.println(int.to_string(42))
```

## Binding Errors

### "Binding not found" error

```
Error: Binding not found: CACHE
```

**Fix:** Check your `gleam.toml` has the binding:

```toml
[cloudflare.bindings]
kv = ["CACHE"]  # Must match exactly (case-sensitive)
```

Then rebuild:

```bash
gleam run -m gflare -- build
```

### Binding works locally but not in production

**Fix:** Deploy secrets separately:

```bash
wrangler secret put API_KEY
```

## Dev Server Issues

### Port already in use

```
Error: Port 8787 is already in use
```

**Fix:** Kill the process using the port:

```bash
# Find and kill the process
lsof -ti:8787 | xargs kill -9

# Or use a different port
gleam run -m gflare -- dev --port 8788
```

### Dev server starts but returns 500

**Fix:** Check the terminal output for errors. Common causes:
- Missing bindings in `gleam.toml`
- SQL syntax errors
- Missing environment variables

## Deployment Issues

### "Account ID required" error

**Fix:** Set your Cloudflare account ID:

```bash
export CLOUDFLARE_ACCOUNT_ID=your_account_id
# Or add to wrangler.toml
```

### "Worker name already exists" error

**Fix:** Change the worker name in `gleam.toml`:

```toml
[cloudflare]
name = "my-worker-unique-name"
```

### Deployment succeeds but worker returns 404

**Fix:** Check that your handler function is exported:

```gleam
// This won't work — function is not public
fn fetch(request, env, ctx) { ... }

// This works — function is public
pub fn fetch(request, env, ctx) { ... }
```

## Database Issues

### D1: "no such table" error

**Fix:** Run migrations first:

```bash
gleam run -m gflare -- db migrate run
```

### Turso: "authentication required" error

**Fix:** Check your environment variables:

```bash
export TURSO_DATABASE_URL=lib://my-db.turso.io
export TURSO_AUTH_TOKEN=eyJ...
```

### Migration fails midway

**Fix:** Check the migration file for SQL errors. You can manually fix the database and delete the migration record:

```sql
DELETE FROM _gflare_migrations WHERE name = '0003_bad_migration.sql';
```

## Performance Issues

### Worker is slow to start

**Fix:** This is normal for cold starts. Subsequent requests will be faster.

### KV reads are slow

**Fix:** Use cache TTL for frequently accessed data:

```gleam
let opts = kv.get_options_with(type_: "json", cache_ttl: Some(60))
```

## Getting More Help

1. Check the [Getting Started](getting-started.md) guide
2. Review the [Error Handling](error-handling.md) patterns
3. Check Cloudflare's [Workers documentation](https://developers.cloudflare.com/workers/)
4. Open an issue on [GitHub](https://github.com/wai-lin/gflare/issues)
