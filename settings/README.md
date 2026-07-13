# Settings Boundaries

The repository versions contracts, schemas, safe defaults, and allowlists only.
`schemas/model-map.example.yaml` is illustrative and is not the live model
selection.

The real model mapping remains local and may vary by host or account. Never
version full settings, provider credentials, API keys, MCP environment values,
MCP trust state, UI preferences, session state, or private absolute paths.

The v0.1 installer may report recommendations from the example, but it must not
silently merge unknown settings or overwrite a local mapping. A host that cannot
select a model should record the degradation and continue with an available
mechanism rather than exposing local configuration.
