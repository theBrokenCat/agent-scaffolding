# Contrato de repositorio GitHub

## Configuracion inicial

- El repositorio debe ser privado al crearse.
- Antes de planificar un ruleset, comprueba si la cuenta y el repositorio
  soportan branch protection para repositorios privados.
- Si esta soportado, la primera publicacion de `main` forma parte del bootstrap
  y ocurre antes de activar el ruleset, porque la rama debe existir para poder
  protegerla. Activa el ruleset inmediatamente despues.
- Si no esta soportado, manten el repositorio privado y aplica los controles
  procedimentales de este contrato sin afirmar que existe proteccion tecnica.
  Como alternativa, el usuario puede decidir usar un plan Pro o hacer publico el
  repositorio; privado sigue siendo la opcion recomendada.
- No añadas GitHub Actions hasta que el proyecto tenga una verificacion real,
  reproducible y util que ejecutar.

Con `local-only` no consultes ni modifiques GitHub. `autonomous-pr` autoriza
unicamente push de feature branches y crear o actualizar draft PRs. El preflight
remoto, la primera publicacion de `main` y cualquier lectura o cambio de
configuracion requieren autorizacion humana explicita o una preautorizacion
concreta para esa accion.

## Issues y milestones

- Todo cambio parte de un issue: crealo o enlazalo antes de ramificar. La rama es
  `feat/<n>-slug` (n = numero del issue) y la PR lo cierra con `Closes #<n>`.
- El titulo del issue describe el resultado buscado, no la tarea mecanica; el
  cuerpo fija objetivo, alcance y decisiones ya tomadas.
- Usa milestones para agrupar los issues de una misma entrega o release y seguir
  su avance; asigna el issue a su milestone al crearlo cuando aplique.

## Proteccion de `main`

Aplica el ruleset con `scripts/protect-repo <owner/repo> --apply` (dry-run por
defecto; `--all` recorre los repos personales; ambos requieren autorizacion
humana para la primera publicacion de `main` y para el propio ruleset). El
ruleset canonico sobre la rama por defecto:

- requiere pull request para integrar cambios, con
  `required_approving_review_count=0` porque en cuenta personal el autor no puede
  aprobar su propia PR;
- restringe el metodo de merge a squash;
- bloquea force push y borrado de la rama;
- requiere que todas las conversaciones esten resueltas
  (`required_review_thread_resolution=true`);
- exige el check `tests` (capa determinista). El check `reviewer` se añade con
  `protect-repo --with-reviewer` solo despues de configurar el secret, implementar
  su harness y activar la variable de repositorio `AGENT_REVIEWER_ENABLED=true`,
  comprobando una revision ejecutada sobre el SHA correspondiente.
- Con la variable desactivada o ausente, CI publica `reviewer-disabled`: informa
  de la ausencia de revision y no satisface un check requerido `reviewer`.
  Activado, la falta del secret o del harness y los errores del revisor fallan.
  No exijas `reviewer-disabled` como gate de revision. Si `reviewer` ya era
  requerido, desactivar la variable deja ese gate pendiente, nunca aprobado.

Estas garantias son tecnicas solo despues de comprobar que el ruleset esta activo
(`gh api repos/<owner>/<repo>/rulesets`). Sin ruleset son controles
procedimentales: no exijas una aprobacion humana imposible en un repositorio
personal y exige, antes del merge, revision del agente con evidencia de la
verificacion aplicable.

## Pull requests y merge

- Usa squash merge por defecto.
- El borrado remoto automatico de ramas esta desactivado por defecto. Activalo
  solo si el bloque canonico registra `delete_merged_branches: true` y existe
  autorizacion humana explicita o una preautorizacion concreta para configurar
  y ejecutar ese borrado remoto.
- `scripts/protect-repo --apply` activa el auto-merge de repositorio
  (`allow_auto_merge=true`, squash). Con eso habilitado, encola el auto-merge de
  una PR concreta con `gh pr merge <n> --auto --squash` solo cuando este
  preautorizado; la PR se integra sola en cuanto los checks requeridos (CI y,
  cuando este activo, `reviewer`) esten en verde. Sin preautorizacion, el merge
  sigue siendo un gate manual.
- Abre una draft PR temprano para trabajo multisesion u orquestado, de modo que
  el estado y el diff sean visibles durante la ejecucion.
- Para un cambio pequeño y de una sola sesion, abre una PR normal al finalizar
  la implementacion y su verificacion, solo con autorizacion humana explicita o
  una preautorizacion concreta para crear una PR no-draft.

Fuera de feature-branch push y draft PRs, `autonomous-pr` no concede autoridad
remota adicional. La primera publicacion de `main`, los rulesets y demas cambios
de configuracion, las PR no-draft y cualquier borrado remoto requieren
autorizacion humana explicita o una preautorizacion concreta. El merge sigue
requiriendo la autoridad definida en `AGENTS.md` y `policies/README.md`; la
configuracion del repositorio no la amplia.
