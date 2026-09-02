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

Los roles canonicos viven en [`agents/roles/`](agents/roles/). `scripts/gen-agents`
resuelve el alias de cada rol contra el model map local y lo materializa por host:

```text
~/.codex/agents/<rol>.toml
~/.claude/agents/<rol>.md
```

Es una unidad de instalacion aparte, con su propio manifiesto y su propia
reversion:

```sh
scripts/gen-agents --host codex --role explorer   # ver el render
scripts/scaffolding install --agents              # plan
scripts/scaffolding install --agents --apply
scripts/scaffolding status --agents
scripts/scaffolding doctor --agents
scripts/scaffolding uninstall --agents --apply
```

El destino es contenido generado, no un symlink, asi que `status --agents`
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

```sh
sh tests/contract_test.sh
sh tests/scaffolding_test.sh
sh tests/registry_test.sh
sh tests/gen_agents_test.sh
sh tests/orchestration_test.sh
sh tests/protect_repo_test.sh
```

En cada PR a `main`, [`.github/workflows/ci.yml`](.github/workflows/ci.yml)
ejecuta estos tests como capa determinista. `scripts/protect-repo` aplica por
repositorio el ruleset de `main` y el auto-merge; ver
[`.github/README.md`](.github/README.md).

Un proyecto puede no tener instrucciones de agentes. Cuando aporten valor, sus
archivos locales contienen solo hechos, comandos y restricciones propias del
proyecto; complementan el contrato global y no amplian permisos superiores. El
contrato opcional para proyectos nuevos esta en
[`templates/README.md`](templates/README.md).

## Contratos

- [`AGENTS.md`](AGENTS.md): autoridad comun, preflight, contexto, Git,
  delegacion, verificacion y STOP.
- [`ROUTER.md`](ROUTER.md): seleccion app-first del mecanismo y coste.
- [`profiles/README.md`](profiles/README.md): esfuerzo `fast|standard|deep`,
  aliases `economy|balanced|frontier|critical` y gates de riesgo.
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

El alias del subagente (`economy`, `balanced`, `frontier`, `critical`) fija su
modelo y su reasoning effort. Solo hay dos curvas por defecto, y se sube a la
curva alta cuando se cumple uno de los dos gates: **que toca** (seam critico) o
**cuanto dura** (horizonte largo o sin criterios de aceptacion objetivos).

El presupuesto de concurrencia es de 8 agentes simultaneos, con 3 writers como
maximo. El lote independiente se lanza entero antes de la primera espera, los
hallazgos se agrupan contra un snapshot congelado y se corrigen en un solo lote.
El diseno del piloto que debe validar todo esto, con sus criterios
pre-registrados, esta en
[`docs/pilots/2026-09-02-phase-2-model-routing.md`](docs/pilots/2026-09-02-phase-2-model-routing.md).

## Estado de v0.1

El contrato global, instalador reversible, registro de capacidades, roles y
limites de settings estan implementados. Las pruebas locales cubren dry-run,
migracion explicita, idempotencia, drift, doctor, rollback por fallo y
restauracion. La activacion real, validacion de los tres runtimes y piloto solo
pueden ejecutarse desde el checkout canonico despues del merge autorizado; un
enlace al worktree de la PR quedaria roto al limpiarlo.

No hagas merge, tag ni deploy por el mero hecho de que esta implementacion
exista. Consulta [`tasks/todo.md`](tasks/todo.md) para los gates pendientes.
