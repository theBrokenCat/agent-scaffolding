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

Valida el contrato, el instalador y el registro con:

```sh
sh tests/contract_test.sh
sh tests/scaffolding_test.sh
sh tests/registry_test.sh
```

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
  aliases `economy|balanced|frontier` y gates de riesgo.
- [`agents/README.md`](agents/README.md): roles genericos, briefs, equipos y
  retorno compacto.
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

## Estado de v0.1

El contrato global, instalador reversible, registro de capacidades, roles y
limites de settings estan implementados. Las pruebas locales cubren dry-run,
migracion explicita, idempotencia, drift, doctor, rollback por fallo y
restauracion. La activacion real, validacion de los tres runtimes y piloto solo
pueden ejecutarse desde el checkout canonico despues del merge autorizado; un
enlace al worktree de la PR quedaria roto al limpiarlo.

No hagas merge, tag ni deploy por el mero hecho de que esta implementacion
exista. Consulta [`tasks/todo.md`](tasks/todo.md) para los gates pendientes.
