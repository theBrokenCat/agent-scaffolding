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

## Proteccion de `main`

Cuando el preflight confirme soporte, configura un ruleset que:

- requiera pull request para integrar cambios;
- bloquee force push y borrado de la rama;
- requiera que todas las conversaciones esten resueltas;
- requiera checks solo cuando esos checks existan y representen verificaciones
  reales del proyecto.

Estas garantias son tecnicas solo despues de comprobar que el ruleset esta
activo. Sin ruleset son controles procedimentales: no exijas una aprobacion
humana imposible en un repositorio personal y exige, antes del merge, revision
del agente y del usuario con evidencia de la verificacion aplicable.

## Pull requests y merge

- Usa squash merge por defecto.
- El borrado remoto automatico de ramas esta desactivado por defecto. Activalo
  solo si la instalacion registra `Delete merged branches: yes` y existe
  autorizacion humana explicita o una preautorizacion concreta para configurar
  y ejecutar ese borrado remoto.
- Activa auto-merge para una PR concreta solo cuando este preautorizado por las
  instrucciones vigentes.
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
