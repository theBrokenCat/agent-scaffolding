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

Run: `rg -n "ff-only|force-with-lease|Outline|codebase-memory|tres intentos|dos rondas" policies/README.md`
Expected: cada guardrail y límite tiene una regla concreta.

Commit: `docs: add operational policies`
