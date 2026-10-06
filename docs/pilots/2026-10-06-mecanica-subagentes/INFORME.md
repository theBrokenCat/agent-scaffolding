# Piloto A/B: ¿quitar la mecánica de subagentes del scaffolding?

2026-10-06 · Codex CLI 0.160.1 (`codex exec`, multi-agent V2) y Claude Code 2.1.291 (`claude -p`).
Diseño y regla de decisión: [PREREG.md](PREREG.md), con sus enmiendas. Diff del brazo B: [arm-b.patch](arm-b.patch).

> **Resumen.** En Codex, la sección de mecánica cambia la conducta (esperas más largas y menos forks),
> así que se mantiene, acotada a Codex. En Claude no aporta nada: Claude orquesta bien sin ella,
> siempre que tus fichas estén cargadas. Se publica como dos secciones por host en `agents/README.md`.

> **Corrección (2026-10-06).** Una primera versión de este informe decía que un fork hace que el
> subagente herede el modelo del padre. Era un error de medición: un rollout forkeado reproduce
> primero la historia del padre, incluido su `turn_context`, y el análisis leía ese. Los turnos propios
> del hijo empiezan en `subagent_history_start_ordinal`, y ahí **todos** los hijos corrieron con el par
> de su ficha, también los forkeados. Lo mismo vale para el aviso de `tests/runtime-parity.md` del
> 2-sep (codex-cli 0.151.0): el `explorer` forkeado corrió con `luna/high`.

## Codex

### Resultado

**No conviene quitar la sección.** En el lote limpio, el brazo sin `### Lote y espera` (B) no cumple
la regla pre-registrada por las esperas: mediana de 3 `wait_agent` frente a 1 (×3; 0 timeouts en ambos
brazos, así que son despertares por evento con bounds de 30 s). Llamadas (+24 %) y tokens del lead
(+23 %) quedan justo dentro del umbral de ×1,25. Calidad y reloj, iguales. El brazo A también tuvo un
fork (r4).

### Lote 2 (limpio)

Cada corrida en `/private/tmp/pilot-sinmec/<id>`; ningún lead leyó el repo real.

| Corrida | Brazo | `fork_turns` | Modelo de los hijos (turno propio) | Waits (timeouts) | Bound | Llamadas lead | Tokens lead* | Reloj |
|---|---|---|---|---|---|---|---|---|
| r1 | A | `none` | luna/high ✅ | 1 (0) | 120 s | 17 | 66,5k | 150 s |
| r2 | B | `all` | luna/xhigh ✅ (fork) | 0 (0) | — | 15 | 68,4k | 180 s |
| r3 | B | `none` | luna/xhigh ✅ | 4 (0) | 30 s | 21 | 80,4k | 210 s |
| r4 | A | *omitido* | luna/high ✅ (fork) | 0 (0) | — | 14 | 63,8k | 210 s |
| r5 | A | `none` | luna/xhigh ✅ | 3 (0) | 60–120 s | 19 | 63,0k | 270 s |
| r6 | B | `"2"` | luna ✅ (fork) | 3 (0) | 30 s | 21 | 78,6k | 240 s |

\* input no cacheado + output del lead. Medianas A/B: reloj 210/210 s; llamadas 17/21 (×1,24);
tokens 63,8k/78,6k (×1,23); waits 1/3; timeouts 0/0. Calidad igual en las 6 (puntos clave y todas
las referencias `archivo:línea` válidas). Repo objetivo intacto.

El lote 1 quedó contaminado (4 de 6 leads leyeron el manual del repo real) y solo se usa como dato
observacional; ver la enmienda 1 de [PREREG.md](PREREG.md).

### Lo que muestran las 12 corridas (a posteriori)

- **Routing: 12/12 correcto.** Todos los hijos corrieron con el modelo y effort de su ficha.
- **Bounds de espera:** con la regla leída, bounds de 60 s o más en 4 de 6 corridas con waits; sin
  leerla, 0 de 4 (siempre 30 s). En tareas largas, 30 s multiplica las vueltas del lead.
- **Fork:** 6/7 corridas que leyeron la regla pasaron `fork_turns: "none"`; de las que no la leyeron,
  solo 1/5. Hubo fork con `"all"` (2), omitiendo el parámetro (2, una tras leer "spawnea sin fork") y
  con `"2"` (1). El coste del fork es de contexto, no de modelo: el hijo recibe toda la historia del
  padre en lugar del brief acotado.
- **Lote antes de esperar:** 12/12 lanzaron los 4 explorers antes del primer wait.
- **Overrides de modelo/effort:** 0 en las 12.

### En tus sesiones reales (`scripts/routing-check`, desde el 2-sep)

Ningún subagente del scaffolding corrió fuera del par de su ficha. Sí aparecen unos 85 hilos lanzados
con los tipos built-in de Codex (`default`, `worker`), que no aplican el routing del scaffolding (la
mayoría corrió con `gpt-6-sol`, el modelo del lead).

## Claude Code

Lead `opus` (`claude-opus-5-5`) con effort high. Contrato cargado como memoria de proyecto
(`--setting-sources project,local`: sin tu `CLAUDE.md` global, plugins, hooks ni MCP).

### Resultado

**En Claude la sección no aporta nada.** Con tus fichas cargadas, las 6 corridas lanzaron 4 `explorer`
en paralelo en un único mensaje, cada hijo con el modelo de su ficha (`claude-sonnet-5`), sin override
de `model` (0/24), sin anidar y sin sondeo (en 2 corridas de A el lead programó un `ScheduleWakeup`
de 1200 s como red de seguridad por si no llegaba la notificación). Calidad igual en las 6.

| Corrida | Brazo | ¿Leyó el manual? | Llamadas lead | Tokens lead | Coste* | Reloj |
|---|---|---|---|---|---|---|
| r1 | A | no | 10 | 33,2k | 0,88 $ | 130 s |
| r2 | B | sí | 15 | 54,0k | 1,43 $ | 230 s |
| r3 | B | sí | 19 | 49,7k | 1,12 $ | 130 s |
| r4 | A | no | 12 | 39,0k | 0,86 $ | 100 s |
| r5 | A | no | 15 | 47,4k | 1,18 $ | 180 s |
| r6 | B | sí | 16 | 46,5k | 1,07 $ | 151 s |

\* `total_cost_usd` equivalente de API.

Por la regla, B sale peor (llamadas ×1,33, tokens y coste ×1,27), pero no por la sección: ningún lead
de A abrió el manual y los tres de B sí; esa diferencia es el coste de leer el manual.

### Lo que importa en Claude

1. **Que las fichas estén cargadas.** Sin ellas (lote 1, por un fallo mío), el lead usó `Explore`
   24/24 veces, con Opus en vez de Sonnet: coste mediano 1,42 $ frente a 1,09 $ (+30 %).
2. **Usar las fichas, no los built-in**, y no pasar `model` a `Agent` (en Claude gana a la ficha).
3. **`effort` en las fichas de Claude**: Claude Code ya lo admite; ahora `gen-agents` lo escribe.

## Cambios publicados a partir de este piloto

- `agents/README.md`: `### Codex: lote, fork y espera` (regla de fork explícita y motivo corregido;
  fichas en lugar de `default`/`worker`) y `### Claude: \`Agent\``. `CLAUDE.md` enlaza a la de Claude.
- `scripts/gen-agents`: `effort` y `disallowedTools: Agent` (writers) en las fichas de Claude.
- `scripts/routing-check`: comprueba, desde los rollouts de Codex, el par real de cada subagente.
- `scripts/pilot-run` y `tests/runtime-parity.md`: corregido el artefacto del fork.

## Límites

n = 3 por brazo y host; una tarea de lectura corta (las esperas largas no se ejercitan); solo CLI en
Codex (ni app ni T3 Code); configuración mínima e idéntica en ambos brazos.

## Archivos

`metrics_codex_lote1.tsv`, `metrics_codex_lote2.tsv`, `metrics_claude_sin_fichas.tsv`,
`metrics_claude_con_fichas.tsv` y los scripts `analyze.py` y `analyze_claude.py`. Los datos brutos
(rollouts y transcripciones) no se versionan.
