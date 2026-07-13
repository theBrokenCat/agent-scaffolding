# Fase 1: Contrato global y adaptadores

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`
- Modify: `CLAUDE.md`
- Modify: `GEMINI.md`
- Modify: `templates/README.md`
- Modify: `policies/README.md`

## Step 1: Cambiar la fuente de autoridad

Definir `~/agent-scaffolding` como fuente global. La precedencia sera sistema,
usuario, instrucciones locales del proyecto y contrato global aplicable; ante
conflicto se aplica autoridad y especificidad, sin permitir que una regla local
amplie permisos restringidos por capas superiores.

## Step 2: Definir activacion por host

Documentar estos destinos gestionados:

```text
~/.codex/AGENTS.md   -> ~/agent-scaffolding/AGENTS.md
~/.claude/CLAUDE.md -> ~/agent-scaffolding/CLAUDE.md
~/.gemini/GEMINI.md -> ~/agent-scaffolding/GEMINI.md
```

Los adaptadores deben cargar `AGENTS.md` mediante una ruta soportada y probada
por cada host. Si el import relativo a un symlink no se resuelve, el instalador
creara el enlace auxiliar minimo o generara un adaptador estable desde template;
la prueba runtime decide, no una suposicion.

Contenido por archivo:

- `AGENTS.md` (Codex y contrato comun): autoridad, deteccion app/CLI, preflight,
  router, contexto, Git/GitHub, MCP/Outline, delegacion, verificacion, loops y
  STOP. En Codex App permite ejecucion directa y subagentes; en CLI aplica el
  mismo contrato sin asumir que existe una interfaz de orquestacion.
- `CLAUDE.md`: import del contrato comun y solo diferencias de Claude App/Code,
  como Plan Mode, subagentes/teams, hooks y comprobacion de memoria. Claude no
  queda reducido a orquestador y puede implementar cuando el router lo elija.
- `GEMINI.md`: import del contrato comun y solo diferencias de Gemini App/CLI,
  memoria jerarquica, recarga y fallback de capacidades. Gemini es generalista,
  no design-only, y nunca simula teams o seleccion de modelo no disponibles.

## Step 3: Conservar reglas globales existentes

Integrar en el contrato central las reglas actuales de Outline y
codebase-memory-mcp. No copiar secretos ni settings. El archivo local de cada
proyecto queda opcional y solo contiene hechos o restricciones del proyecto.

## Step 4: Corregir templates y README

Eliminar el schema `agent_scaffolding` obligatorio y la lista de archivos a
instalar por proyecto. `templates/README.md` describira solo un proyecto nuevo
opcional: README, gitignore, instrucciones locales si aportan contexto y PR
template si usa GitHub.

## Step 5: Verificar y commitear

Run: `rg -n 'instalacion base|agent_scaffolding:|debe mencionar|proyecto minimo instalado' README.md templates/README.md AGENTS.md`
Expected: sin requisitos de instalacion local.

Run: `git diff --check`
Expected: exit 0.

Commit: `docs: define global agent contract`
