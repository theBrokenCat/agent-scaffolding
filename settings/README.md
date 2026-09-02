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

## Model map

A model map resolves each portable alias to a concrete model and reasoning
effort. `ROUTER.md` owns the alias vocabulary (`economy`, `balanced`, `frontier`,
`critical`, plus the opt-in `diagnostic` rung); this directory owns only the file
shape.

`scripts/gen-agents` resolves the map in this order and stops at the first hit:

1. `--model-map PATH`
2. `$XDG_CONFIG_HOME/agent-scaffolding/model-map.yaml`
3. `$HOME/.config/agent-scaffolding/model-map.yaml`
4. `settings/schemas/model-map.example.yaml`

The example carries code names, not provider model ids, so it can be read and
tested but never installed: `scripts/scaffolding install --agents --apply` stops
when only the example is available. Copy the example to the local path, replace
the code names with real model ids, and keep that file out of the repository.

Aliases are portable; the model ids behind them are not. Changing the local map
changes what every host materialization selects, so re-run `install --agents` and
the runtime parity check in [`tests/runtime-parity.md`](../tests/runtime-parity.md)
after editing it.
