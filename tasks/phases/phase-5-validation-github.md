# Fase 5: Validacion cruzada y GitHub

**Files:**
- Create: `tests/runtime-smoke.md`
- Modify: `tasks/todo.md`
- Modify: `.github/pull_request_template.md`
- Modify: `README.md`

## Step 1: Validar el instalador en HOME temporal

Run: `sh tests/scaffolding_test.sh && sh tests/registry_test.sh`
Expected: PASS.

Run: `HOME="$(mktemp -d)" scripts/scaffolding install`
Expected: dry-run con tres instrucciones globales y cero mutaciones.

## Step 2: Validar hosts sin proyecto

Desde un directorio temporal vacio, pedir a Codex, Claude y Gemini que devuelvan
la version del contrato y clasifiquen un caso `fast` y uno `deep`. Registrar
comando, version, exit, mecanismo y desviacion; no almacenar transcripciones.

## Step 3: Validar precedencia y contexto

Repetir desde un repo fixture con instrucciones locales y desde un subdirectorio.
Comprobar que las reglas locales anaden contexto, que una restriccion no amplia
autoridad, que `fast` no pregunta y que `deep` recomienda antes de actuar.

## Step 4: Validar degradaciones

Simular host sin seleccion de modelo, sin teams y sin token accounting. Debe
elegir fallback explicito o STOP, nunca fingir que lanzo Sol/Terra/Luna ni crear
delegacion no medible sin la autoridad prevista.

## Step 5: Revisar y publicar la PR

Run: `git diff --check && git status --short`
Expected: solo archivos de esta implementacion.

Run: `gh pr view 1 --json isDraft,mergeable,reviewDecision,statusCheckRollup,headRefOid`
Expected: draft abierta, head actual y checks conocidos.

Actualizar cuerpo/evidencia y hacer push de checkpoints verdes. No mergear.

Commit: `test: validate global activation`
