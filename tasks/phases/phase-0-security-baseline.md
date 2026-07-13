# Fase 0: Seguridad y baseline

**Files:**
- Create: `tasks/baseline.md`
- Modify locally, never commit: Outline credentials and host backups

## Step 1: Rotar credenciales

Rotar primero las credenciales de Outline que aparecieron en una salida anterior.
No registrar valores antiguos ni nuevos en terminal, plan, commit o PR.

Expected: el MCP de Outline conecta con el valor nuevo y el anterior deja de ser valido.

## Step 2: Crear inventario redactado

Registrar en `tasks/baseline.md` solo paths, tipo de objeto, propietario,
estrategia (`link`, `merge`, `external`, `local`) y checksum. Para TOML/JSON,
listar unicamente nombres de claves allowlisted; nunca valores.

Run: `find "$HOME/.codex" "$HOME/.claude" "$HOME/.gemini" -maxdepth 2 \( -type f -o -type l \) -print`
Expected: lista de paths para clasificar manualmente, sin leer ni imprimir valores.

## Step 3: Verificar Git y GitHub

Run: `git status --short --branch`
Expected: rama `feat/v0.1` y solo cambios de plan previstos.

Run: `gh pr view 1 --json state,isDraft,mergeable,headRefOid,baseRefName`
Expected: PR abierta, draft, base `main` y head igual a `git rev-parse HEAD` tras push.

## Step 4: Gate de secretos y commit

Run: `git diff --check`
Expected: exit 0.

Run: `rg -n -i '(api[_-]?key|token|password|secret)\s*[:=]\s*[^<[:space:]]+' --glob '!tasks/phases/*' .`
Expected: sin valores reales; revisar manualmente cada match legitimo.

Commit: `chore: record migration baseline`
