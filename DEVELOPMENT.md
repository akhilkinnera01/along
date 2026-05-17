# Development

AlongKit development is organized around small, reviewable branches. The goal is a lightweight codebase where each change earns its place.

## Workflow

1. Open or choose a GitHub issue for the work.
2. Create a branch from `main`.
3. Keep the branch focused on one outcome.
4. Commit each complete unit separately.
5. Run local checks before pushing.
6. Open a pull request and wait for CI.

Use branch names that describe the work:

```text
workflow/6-developer-docs
runtime/5-mission-replay
templates/8-stay-with-me
```

Use plain commit messages:

```text
Add mission replay validation
Cover replay sequence gaps
Update developer workflow docs
```

Avoid catch-all commits. A reviewer should be able to understand why each commit exists.

## Local Checks

Run these before pushing:

```sh
swift build -Xswiftc -warnings-as-errors
swift test
```

Also scan changes before committing:

```sh
git diff --cached
git grep -n -P "\\x{2014}"
```

Do not commit credentials, signing material, editor state, local planning files, private user data, or generated local build output.

## Design Rules

- Keep `AlongCore` independent of Apple UI and device frameworks.
- Keep provider adapters separate from tool adapters.
- Prefer deterministic template logic before model calls.
- Require approval before externally visible or risky actions.
- Keep memory optional and user-approved.
- Add dependencies only when the weight is justified.
