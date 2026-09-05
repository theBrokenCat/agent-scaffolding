# Agent Scaffolding

Contrato global, pequeno y verificable para trabajar con Codex, Claude y Gemini
desde apps o CLI. La fuente canónica vive en `~/agent-scaffolding`; no se instala
una copia en cada proyecto.

## Activacion global

Los destinos gestionados de v0.1 son:

```text
~/.codex/AGENTS.md   -> ~/agent-scaffolding/AGENTS.md
~/.claude/CLAUDE.md -> ~/agent-scaffolding/CLAUDE.md
~/.gemini/GEMINI.md -> ~/agent-scaffolding/GEMINI.md
```

El enlace no basta como prueba. Cada host debe demostrar en runtime que carga el
contrato comun. Instala siempre desde el checkout canonico de `main`, nunca desde
un worktree temporal:

```sh
scripts/scaffolding install
scripts/scaffolding install --apply
scripts/scaffolding status
scripts/scaffolding doctor
scripts/scaffolding uninstall
scripts/scaffolding uninstall --apply
```

Todos los comandos son dry-run salvo `--apply`. Si existe cualquiera de los
tres destinos, el instalador aplica STOP. Revisa primero el plan y usa
`install --migrate-existing --apply` solo cuando quieras guardar y sustituir
explicitamente esos destinos. El manifiesto y los backups quedan fuera del repo
en `~/.local/state/agent-scaffolding/`; `uninstall --apply` restaura archivos,
symlinks —incluidos los rotos— y ausencias anteriores.

## Definiciones de subagente por host

Los roles canonicos viven en [`agents/roles/`](agents/roles/) y **siguen siendo
cuatro**. `scripts/gen-agents` resuelve sus alias contra el model map local y
materializa **un archivo por par (rol, estado)** —base y escalado— por host:

```text
~/.codex/agents/<rol>-<estado>.toml
~/.claude/agents/<rol>-<estado>.md
```

Un archivo generado es un estado materializado, no un rol nuevo. Los estados son
`explorer-economy` / `explorer-balanced`, `implementer-economy` /
`implementer-balanced` / `implementer-frontier`, `spec-reviewer-frontier-high` /
`spec-reviewer-frontier-xhigh` y `quality-reviewer-frontier` /
`quality-reviewer-critical`; `explorer` conserva ademas su nombre desnudo para
seguir sobrescribiendo el built-in del host.

Cada definicion incluye el cuerpo completo de su ficha y el contrato comun de
retorno; puede usarse desde otro proyecto sin resolver rutas del scaffolding.
El retorno separa el estado de ejecucion del veredicto de revision: `completed`
por si solo no significa aprobado. El formato canonico vive en
[`agents/README.md`](agents/README.md#envelope-de-retorno).

Son archivos separados porque el host resuelve el routing por el agente nombrado:
con `agent_type`, la definicion gana a cualquier override de `model` o
`reasoning_effort`. Por eso escalar es despachar otro nombre, nunca pasar un
override.

Los agentes de cada host tienen una unidad de instalacion separada de las
instrucciones, con manifiesto y reversion propios. Se puede retirar un host
sin afectar al otro:

```sh
scripts/gen-agents --host codex --role explorer-economy    # ver el render
scripts/scaffolding install --agents --host codex          # plan
scripts/scaffolding install --agents --host codex --apply
scripts/scaffolding status  --agents --host codex
scripts/scaffolding doctor  --agents --host codex
scripts/scaffolding uninstall --agents --host codex --apply
```

El destino es contenido generado, no un symlink, asi que `status --agents --host H`
distingue dos derivas: `destination changed` cuando han editado el archivo del
host y `render-changed` cuando ha cambiado el rol, el model map o el generador.

Instalar exige un model map local en `~/.config/agent-scaffolding/model-map.yaml`.
El ejemplo del repositorio lleva nombres en clave, no ids de modelo, y el
instalador se niega a copiarlos a un host. Gemini no expone formato de subagente
y queda fuera de esta unidad.

Un archivo instalado no prueba que el host ejecute en ese modelo y ese effort:
eso se comprueba con [`tests/runtime-parity.md`](tests/runtime-parity.md).

El manifiesto guarda una entrada por destino, asi que **anadir o quitar un rol
canonico invalida una unidad ya instalada**. Falla en voz alta y explica la
recuperacion manual; no hay migracion automatica, porque el contrato fija cuatro
roles genericos y cambiar ese conjunto es una decision, no una rutina.

Valida el contrato, el instalador y el registro con:

Las pruebas usan shell y Python 3.11 o posterior (incluido `tomllib` de la
biblioteca estandar); no requieren llamadas a modelos ni credenciales reales.

```sh
sh tests/contract_test.sh
sh tests/scaffolding_test.sh
sh tests/registry_test.sh
sh tests/gen_agents_test.sh
sh tests/ci_reviewer_test.sh
sh tests/orchestration_test.sh
sh tests/pilot_run_test.sh
sh tests/protect_repo_test.sh
```

En cada PR a `main`, [`.github/workflows/ci.yml`](.github/workflows/ci.yml)
ejecuta estos tests como capa determinista. `scripts/protect-repo` aplica por
repositorio el ruleset de `main` y el auto-merge; ver
[`.github/README.md`](.github/README.md).

La revision automatica se activa con `AGENT_REVIEWER_ENABLED=true` despues de
configurar su credencial y harness. Desactivada aparece como `reviewer-disabled`,
que no acredita revision; activada publica `reviewer` y falla ante configuracion
incompleta o errores. La revision independiente sigue siendo un gate de
integracion aunque el revisor automatico no este configurado.

Un proyecto puede no tener instrucciones de agentes. Cuando aporten valor, sus
archivos locales contienen solo hechos, comandos y restricciones propias del
proyecto; complementan el contrato global y no amplian permisos superiores. El
contrato opcional para proyectos nuevos esta en
[`templates/README.md`](templates/README.md).

## Contratos

- [`AGENTS.md`](AGENTS.md): autoridad comun, preflight, contexto, Git,
  delegacion, verificacion y STOP.
- [`ROUTER.md`](ROUTER.md): seleccion app-first del mecanismo y coste.
- [`profiles/README.md`](profiles/README.md): indice compatible; esfuerzo y
  aliases se resuelven en el router, sin una capa adicional de reglas.
- [`agents/README.md`](agents/README.md): roles genericos, alias por rol, briefs,
  presupuesto de concurrencia, orquestacion y retorno compacto.
- [`agents/roles/`](agents/roles/): ficha canonica de cada rol, con alias, effort
  y disparador de escalada en el frontmatter.
- [`policies/README.md`](policies/README.md): limites operativos de Git, contexto,
  seguridad, produccion y loops.
- [`CLAUDE.md`](CLAUDE.md) y [`GEMINI.md`](GEMINI.md): diferencias reales de
  cada host, sin asignarles un rol fijo.
- [`templates/README.md`](templates/README.md): estructura local opcional y bajo
  demanda.

## Modelo de trabajo

`app-direct` es el default. Para trabajo sustancial, la app recomienda si debe
ejecutar directamente, delegar, paralelizar, relevar a CLI o combinar ambos. La
confirmacion se pide solo cuando esa eleccion cambia coste, autoridad, superficie
de escritura o destino de ejecucion.

La app conserva decisiones, contratos compartidos, integracion y verificacion.
Los workers reciben contexto acotado, usan roles genericos y devuelven un
envelope compacto. Los writers trabajan sobre paths disjuntos y en worktrees
separados; no existe delegacion anidada.

Los cuatro roles son opciones, no una cadena obligatoria. En trabajo delegado,
el lead define, un implementer ejecuta, un quality-reviewer revisa y el lead
integra. Exploracion y revision de especificacion se anaden solo con una pregunta
o riesgo concreto. La ejecucion directa conserva la revision independiente
exigida por el gate de integracion.

El router conserva el mapping actual como politica provisional. Se decide primero
aceptacion y division del objetivo; la escalada se justifica por riesgo critico o
razonamiento inseparable, no por el numero de pasos. No se afirma superioridad de
modelos ni ahorro sin evidencia comparable.

Para trabajo multisesion, usa el [relevo por objetivo](agents/README.md#trabajo-multisesion)
en el issue o documento existente. El estado debe permitir retomar con el checkout,
las dependencias, la evidencia y el siguiente paso correctos.

Los [pilotos historicos](docs/pilots/2026-09-02-phase-2-model-routing.md) se conservan
como evidencia de diseno y ejecucion; no sustituyen el router ni prueban ahorros
globales. Concurrencia, despacho y revision estan en
[agents/README.md](agents/README.md#orquestacion).

## Estado historico de v0.1

El contrato global, instalador reversible, registro de capacidades, roles y
limites de settings estan implementados. Las pruebas locales cubren dry-run,
migracion explicita, idempotencia, drift, doctor, rollback por fallo y
restauracion. La activacion real, validacion de los tres runtimes y piloto solo
pueden ejecutarse desde el checkout canonico despues del merge autorizado; un
enlace al worktree de la PR quedaria roto al limpiarlo.

No hagas merge, tag ni deploy por el mero hecho de que esta implementacion
exista. Consulta [`tasks/todo.md`](tasks/todo.md) para los gates pendientes.
