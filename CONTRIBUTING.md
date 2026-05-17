# Contributing

AlongKit is intentionally small. Contributions should preserve clear module boundaries, deterministic tests, and explicit user approval for risky actions.

## Local Checks

Run before opening a change:

```sh
swift build -Xswiftc -warnings-as-errors
swift test
```

Do not commit credentials, local planning files, editor state, signing material, or private user data.

## Commit Style

Use focused conventional commits:

```text
feat(core): add mission replay
test(core): cover replay gaps
ci(repo): add Swift package checks
```

Each commit should compile and pass tests whenever feasible.

