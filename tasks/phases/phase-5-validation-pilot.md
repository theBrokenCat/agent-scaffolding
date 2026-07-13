# Fase 5: Validación, GitHub y piloto

**Files:**
- Modify: `tasks/todo.md`
- Modify: `README.md`
- Create only if justified: `scripts/validate-project`

## Step 1: Validar estructura y referencias

Comprobar archivos obligatorios, imports `@AGENTS.md`, enlaces relativos,
directorios vacíos y tamaño de instrucciones. Primero usar comandos estándar;
crear script solo si la validación manual resulta repetitiva.

## Step 2: Ejecutar presión del router

Simular seis tareas con Codex, Claude y Gemini. Registrar perfil elegido,
contexto cargado, agentes lanzados y desviaciones. Corregir contratos, no añadir
excepciones específicas para cada ejemplo.

## Step 3: Publicar en GitHub

Crear repositorio privado, configurar `origin`, subir rama y abrir draft PR.
Aplicar reglas de `main` después del bootstrap inicial.

## Step 4: Verificar el ciclo Git completo

Confirmar checks, revisión, squash merge, `git pull --ff-only`, eliminación de
rama y limpieza del worktree. No activar auto-merge sin autorización.

## Step 5: Elegir piloto y cerrar v0.1

Elegir un proyecto de riesgo moderado. No desplegar el scaffolding durante esta
fase; dejar documentados el criterio de éxito y la reversión. Completar Review
en `tasks/todo.md` y etiquetar `v0.1.0` solo tras el piloto satisfactorio.

Run: `git status --short`
Expected: empty after final commit.

Run: `git log --oneline --decorate -5`
Expected: un commit lógico por fase.

Commit: `test: validate scaffolding workflow`
