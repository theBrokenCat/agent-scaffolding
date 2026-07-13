# Fase 2: Router app-first y contexto

**Files:**
- Modify: `ROUTER.md`
- Modify: `profiles/README.md`
- Modify: `agents/README.md`
- Modify: `AGENTS.md`

## Step 1: Implementar el preflight contractual

Anadir el bloque canonico:

```text
Recomiendo: <app-direct|app-delegated|app-parallel|cli-handoff|hybrid>
Motivo: <una frase>
La app conservara: <decisiones e integracion>
Delegare: <scope o nada>
Confirmacion necesaria: <si/no>
```

`fast` no pregunta. `standard/deep`, escrituras amplias, equipos, seguridad,
produccion o relevo piden decision cuando la opcion cambia coste o autoridad.

## Step 2: Definir el router

Clasificar en este orden: instruccion explicita, autoridad, mutacion, riesgo,
coste de contexto, independencia y capacidades del host. `app-direct` es el
default. CLI es una opcion, no el destino obligatorio.

## Step 3: Definir modelos y roles

Usar `economy`, `balanced` y `frontier`; documentar Luna, Terra y Sol solo como
mapping local inicial. Mantener cuatro roles: explorer, implementer,
spec-reviewer y quality-reviewer. Los dominios se expresan como briefs.

## Step 4: Definir envelopes y equipos

Todo retorno contiene exactamente: `status`, `summary`, `changes_or_findings`,
`verification`, `risks`, `references`, `next_action`. Prohibir logs completos
por defecto. Writers paralelos declaran paths disjuntos y worktree; no hay
delegacion anidada.

## Step 5: Probar tabla de decisiones y commitear

Casos: typo, feature acotada, investigacion grande, frontend/backend disjuntos,
security diff, hotfix de produccion, usuario pide CLI y host sin seleccion de
modelo. Registrar mecanismo, pregunta, modelo, contexto retenido y gate.

Run: `git diff --check`
Expected: exit 0.

Commit: `docs: define app first orchestration`
