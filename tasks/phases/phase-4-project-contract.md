# Fase 4: Contrato de proyecto y pull requests

**Files:**
- Create: `templates/README.md`
- Create: `.github/README.md`
- Create: `.github/pull_request_template.md`

## Step 1: Definir el proyecto mínimo

El contrato base generará únicamente `README.md`, `AGENTS.md`, `CLAUDE.md`,
`GEMINI.md`, `.gitignore` y plantilla de PR. Describir condiciones exactas para
crear tareas, lecciones, ADRs, incidentes y runbooks.

## Step 2: Definir GitHub

Documentar repositorio privado, protección de `main`, squash merge, borrado de
ramas, checks requeridos y resolución de conversaciones.

## Step 3: Crear plantilla de PR

Incluir problema, cambios, verificación real, riesgos, rollback, documentación,
seguridad y trabajo diferido. Las secciones no aplicables deben poder marcarse
sin generar documentación adicional.

## Step 4: Verificar y commitear

Run: `find . -type d -empty -not -path './.git/*'`
Expected: no output.

Commit: `docs: add project and pull request contracts`
