# Fase 2: Router, perfiles y delegación

**Files:**
- Create: `ROUTER.md`
- Create: `profiles/README.md`
- Create: `agents/README.md`

## Step 1: Definir el router

Escribir la precedencia completa, preguntas de clasificación, perfiles base y
overlays. Toda ruta debe terminar en un perfil, un criterio de finalización y
una decisión explícita sobre delegación.

## Step 2: Definir perfiles

Para cada perfil incluir: disparadores, contexto que carga, acciones permitidas,
gates, documentación y salida. `audit` será read-only; `security` activará los
skills especializados; `production` exigirá rollback y aprobación.

## Step 3: Definir agentes

Documentar agente único, subagente, despacho paralelo y equipo. Incluir contrato
de lanzamiento: objetivo, scope, archivos, dependencias, modelo de coste,
worktree, verificaciones y formato de retorno.

## Step 4: Ejecutar escenarios de tabla

Comprobar manualmente: typo, feature, auditoría `/improve`, revisión de seguridad,
hotfix de producción y cambio frontend/backend paralelo. Registrar perfil y
mecanismo esperado en `agents/README.md` como tabla de ejemplos.

## Step 5: Verificar y commitear

Run: `rg -n "solo|software|audit|security|production|orchestrated" ROUTER.md profiles/README.md`
Expected: los seis perfiles están definidos y enrutables.

Commit: `docs: define workflow routing and delegation`
