# Fase 4: Skills, agentes y settings seguros

**Files:**
- Create: `skills/README.md`
- Create: `skills/registry.yaml`
- Create: `agents/roles/explorer.md`
- Create: `agents/roles/implementer.md`
- Create: `agents/roles/spec-reviewer.md`
- Create: `agents/roles/quality-reviewer.md`
- Create: `settings/README.md`
- Create: `settings/schemas/model-map.example.yaml`
- Create: `tests/registry_test.sh`
- Modify: `scripts/scaffolding`

## Step 1: Definir schema y tests RED

Cada skill registra `id`, `owner`, `hosts`, `trigger`, `mode`, `cost`, `source`
y `managed`. `external` nunca se enlaza ni copia. Los tests rechazan ids
duplicados, paths inexistentes gestionados, frontmatter invalido y tool refs no
declaradas.

Run: `sh tests/registry_test.sh`
Expected: FAIL hasta existir registry y validador.

## Step 2: Curar skills

Registrar Ponytail, improve, Git/GitHub, worktrees, planning, debugging, TDD,
review, equipos y Codex Security con triggers no solapados. Mantener plugins
externos en su instalador original y enlazar individualmente solo skills propias.

## Step 3: Crear roles nativos

Cada rol define cuando usarlo/no usarlo, input, autoridad, output envelope y
STOP. No fijar frontend/backend/database como identidades. Adaptar a cada host
solo donde soporte agentes nativos; en el resto, el rol sigue siendo un brief.

## Step 4: Settings y modelos

El schema de ejemplo usa:

```yaml
models:
  economy: luna
  balanced: terra
  frontier: sol
```

El mapping real queda ignorado/local. Versionar allowlists y ejemplos, nunca
credenciales, MCP env, trust state, UI preferences o settings completos. El
instalador solo informa recomendaciones en v0.1 salvo que exista un merge seguro
probado por host.

## Step 5: GREEN y commit

Run: `sh tests/registry_test.sh`
Expected: PASS y cero duplicados gestionados.

Run: `git diff --check`
Expected: exit 0.

Commit: `feat: add capability registry`
