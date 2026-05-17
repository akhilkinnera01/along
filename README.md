# AlongKit

AlongKit is a lightweight Swift package for building wrist-first mission workflows across iPhone and Apple Watch.

The package is intentionally small. It provides the shared runtime contracts for mission state, event replay, foreground scheduling, tool approvals, provider routing, and optional user-controlled memory. Native iPhone and Apple Watch apps can sit on top of these modules without forcing the core runtime to depend on UI frameworks.

## Design Values

- Small core surface area.
- Local-first mission history.
- Explicit user approval for risky actions.
- No silent memory writes.
- Provider adapters behind simple Swift protocols.
- No third-party dependencies in the core package.

## Modules

- `AlongCore`: mission events, snapshots, scheduling, tool contracts, approvals, and the small runtime loop.
- `AlongMemory`: optional memory record contracts with explicit approval requirements.
- `AlongOpenAI`: injectable OpenAI provider bridge.
- `AlongGemini`: injectable Gemini provider bridge.

## Mission Templates

AlongKit names templates the way users would ask for them:

- Stay With Me
- Run With Me
- Focus With Me
- Capture For Me

The core package defines the template identifiers and state model. App targets own the final voice, watch, phone, notification, and location experiences.

## Development

```sh
swift test
```

The package currently has no external dependencies.

