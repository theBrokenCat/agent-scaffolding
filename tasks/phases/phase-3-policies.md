# Fase 3: Políticas operativas

**Files:**
- Create: `policies/README.md`

## Step 1: Política Git y GitHub

Definir comandos y estados desde `fetch` hasta cleanup. Autorizar commits,
push de rama y draft PR; prohibir push directo a `main`, force-push implícito,
merge no autorizado y operaciones destructivas.

## Step 2: Política de coste

Definir niveles `fast`, `standard` y `deep` sin fijar modelos concretos. Limitar
subagentes, cargas de documentos, reindexados y rondas de revisión/CI.

## Step 3: Política MCP y Outline

Hacer graph-first el descubrimiento de código. Separar estado operativo del
repositorio y conocimiento transversal de Outline. Prohibir secretos y escrituras
en Outline no solicitadas.

## Step 4: Seguridad y documentación

Definir cuándo activar skills de seguridad, cuándo crear ADR, incidente, runbook,
`tasks/active.md` o `tasks/lessons.md`, y cuándo no crear ninguno.

## Step 5: Verificar y commitear

Run:

```sh
set -eu
rg -q -- 'pull --ff-only' policies/README.md
rg -q -- '--force-with-lease' policies/README.md
rg -q -- 'Outline' policies/README.md
rg -q -- 'codebase-memory-mcp' policies/README.md
rg -q -- 'tres intentos' policies/README.md
rg -q -- 'presupuesto agregado máximo de dos rondas' policies/README.md
rg -q -- '`standard` una y `deep` una' policies/README.md
rg -q -- 'git config --get' policies/README.md
rg -q -- '<redacted>' policies/README.md
git diff --check
```

Expected: cada comando termina con código `0` de forma independiente.

Commit: `docs: add operational policies`
