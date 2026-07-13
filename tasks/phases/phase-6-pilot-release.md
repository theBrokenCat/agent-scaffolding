# Fase 6: Piloto y release

**Files:**
- Create: `docs/pilots/personal-life-v0.1.md`
- Modify: `tasks/todo.md`
- Modify: `README.md`

## Step 1: Preparar piloto aislado

Verificar que `personal-life` esta limpio, actualizar `origin/main` y crear una
rama/worktree de piloto. No anadir AGENTS/CLAUDE/GEMINI para activar el flujo;
solo se permiten cambios propios de una tarea real seleccionada.

## Step 2: Ejecutar muestra

Ejecutar al menos una tarea fast directa, una standard con recomendacion y una
tarea delegable. Registrar mecanismo recomendado/elegido, workers, tokens si el
host los informa, tamano del retorno, friccion, errores y resultado Git.

## Step 3: Evaluar gates

Exito: activacion global demostrada, ninguna regla local obligatoria, retorno
compacto, sin secretos, baseline no empeorado y rama/PR recuperables. Fallo:
revertir o abandonar solo el worktree de piloto y abrir una correccion acotada
en `agent-scaffolding`.

## Step 4: Cerrar documentacion

Completar `docs/pilots/personal-life-v0.1.md` y Review en `tasks/todo.md` con
evidencia, desviaciones y recomendacion de release.

Commit: `docs: record v0.1 pilot`

## Step 5: Gates humanos de release

Solicitar autorizacion explicita para squash merge de la PR. Tras confirmar el
merge, actualizar el checkout principal con `git pull --ff-only`, ejecutar
`scripts/scaffolding doctor` y pedir una segunda autorizacion para crear y
publicar el tag `v0.1.0`.
