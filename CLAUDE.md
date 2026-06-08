# Venndle — Claude Code Rules

## Stack
- **Rails 8.1.3** (Ruby), PostgreSQL, Devise auth
- **Test framework**: Minitest (`rails test`)
- **Linter**: RuboCop (`bundle exec rubocop`)
- **Security scanner**: Brakeman (`bundle exec brakeman -q`)

---

## Rules

### Before marking any task done
1. Run the full test suite: `rails test`
2. Run RuboCop: `bundle exec rubocop`
3. Run Brakeman: `bundle exec brakeman -q`
All three must pass with no new failures or warnings introduced.

### Tests
- Never delete, skip, or weaken an existing test.
- Every new model, controller action, or helper method must have at least a basic test in the matching `test/` file.
- Tests live in `test/models/`, `test/controllers/`, `test/helpers/`, `test/integration/` — mirror the `app/` structure.
- Use fixtures (`test/fixtures/`) for test data; do not seed the development DB in tests.

### Commits
- Commit after each working, tested feature — never commit broken code.
- Commit message format: plain-English summary of what changed and why (not a branch-name slug).
- One logical change per commit; don't bundle unrelated fixes.

### Scope
- Work in small, focused tasks.
- Don't refactor or clean up surrounding code unless it's directly in the way of the task.
- Don't add error handling, fallbacks, or abstraction layers for scenarios that don't exist yet.

### Database
- Never modify `db/schema.rb` by hand — only through migrations.
- Every migration must be reversible (`def change` with reversible operations, or explicit `up`/`down`).
- Column additions to large tables should use `add_column` with a default, not a multi-step backfill, unless explicitly required.

### ERB inside `<script>` blocks
- **Always use `.html_safe` on any `.to_json` call inside a `<script>` block.** Rails HTML-escapes `<%= %>` output by default — `to_json` on a string produces `"value"` with double-quotes, which ERB turns into `&quot;value&quot;`. In a `<script>` block `&quot;` is a literal `&` character and causes a JS SyntaxError that silently kills the entire script block. This does NOT apply to HTML attributes (e.g. `onclick="..."`) where the browser decodes entities before running JS.
- Example: `<%= puzzle.scheduled_date.to_json.html_safe %>` ✓ — `<%= puzzle.scheduled_date.to_json %>` ✗

### Security
- Never expose admin-only data (play counts, user details) to non-admin users — check `current_user.admin?` server-side, not just in views.
- Never interpolate user input directly into SQL — use ActiveRecord query methods or parameterised queries.
- Brakeman warnings are blocking; resolve them before merging.

### Deployment
- The app deploys automatically to Railway on push to `staging`.
- **Push commits directly to `staging`** — do not create feature branches or PRs. After every task: `git add → git commit → git push origin HEAD:staging`.
- Never push directly to `main`. Only `staging` → `main` promotions go to production.
