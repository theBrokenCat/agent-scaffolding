# Fase 1: Contrato común y adaptadores

**Files:**
- Create: `README.md`
- Create: `AGENTS.md`
- Create: `CLAUDE.md`
- Create: `GEMINI.md`

## Step 1: Crear el README

Documentar propósito, arquitectura, instalación manual y regla de evolución:
ningún directorio o automatización se añade sin un caso real.

## Step 2: Crear AGENTS.md

Incluir, en este orden: fuentes de verdad, protocolo inicial, router, contexto,
ejecución, Git, delegación, verificación, documentación y paradas. Mantenerlo
por debajo de 200 líneas y sin detalles exclusivos de Claude o Gemini.

## Step 3: Crear CLAUDE.md

Primera línea operativa: `@AGENTS.md`. Añadir únicamente carga de skills,
Plan Mode para trabajo no trivial, selección de subagentes/equipos, hooks como
enforcement y `/memory` para comprobar el contexto cargado.

## Step 4: Crear GEMINI.md

Importar `@AGENTS.md`. Añadir `/memory show`, `/memory reload`, contexto
jerárquico y relevo mediante una issue o tarea cuando falte una capacidad.

## Step 5: Verificar y commitear

Run: `rg -n "push directo|codebase-memory|Outline|worktree" AGENTS.md CLAUDE.md GEMINI.md`
Expected: las reglas comunes aparecen en `AGENTS.md`; los adaptadores solo las referencian.

Run: `git diff --check`
Expected: exit 0.

Commit: `docs: add shared agent contract`
