# Issue 30: estado de instalación desde worktrees

Registro de contrato y relevo de la prueba nocturna del 05/09/2026. El estado de
entrega se consulta en el [issue #30](https://github.com/theBrokenCat/agent-scaffolding/issues/30).
Base de código: `48fa15a5d856b3541453b5fd823143bb7d4df1a1`.

## Resultado y aceptación

- doctor/status reconocen la instalación canónica desde un worktree del mismo
  repositorio y declaran ese contexto mediante NOTE.
- La identidad se prueba con Git common dir resuelto, sin variables Git heredadas.
  SHA, fuentes y renders se consultan en el checkout canónico, no en el caller.
- Otros repositorios, roots ausentes/no Git y manifests corruptos se rechazan;
  no se ejecuta un generador externo antes de verificar identidad.
- Se conservan las validaciones de symlinks, backups y destinos modificados.
- install/uninstall mantienen STOP desde un root distinto, incluido dry-run.

## Propiedad y continuidad

El lead conserva decisiones, revisión, publicación e instalación. Los workers
solo modificaron scripts/scaffolding, scripts/lib/manifest.sh,
tests/scaffolding_test.sh y el registro. Las dos sesiones fueron procesos Codex
nuevos con un implementer-frontier sin fork, ni overrides, ni delegación anidada.

Sesión A dejó regresión RED y relevo. El lead detectó que el fixture asumía .git
como fichero; anotó esa corrección en el registro. Sesión B lo leyó desde cero,
creó un Git temporal con worktree real y HEAD diferente, reprodujo RED y obtuvo
GREEN tras el arreglo. No se reutilizó el historial de conversación de A.

En integración, el lead encontró que GIT_DIR/GIT_COMMON_DIR podían falsear la
identidad o el SHA. Añadió una regresión que falló y aisló las consultas Git con
la lista de variables locales de `git rev-parse --local-env-vars`.

## Evidencia y siguiente paso

Baseline de ocho suites verde. Sesión A: RED esperado por invalid manifest.
Sesión B: RED/GREEN y ocho suites verdes, verificadas después por el lead.
Regresión adversa: `FAIL: foreign repository accepted through GIT_DIR` antes de
la corrección del lead. Los tests usan exclusivamente fixtures y HOME temporal.

El candidato necesita suite final, revisión independiente y CI antes de integrar.
Después del merge autorizado: actualizar el checkout canónico, refrescar las
unidades instaladas y comprobar doctor/status desde ambos checkouts. El SHA
revisado, los resultados terminales y el estado de merge constan en la PR.
