# Piloto A/B: contrato con y sin mecanica de subagentes (pre-registro)

Registrado antes de ejecutar, 2026-10-06. No se reinterpreta despues de ver los numeros.

## Pregunta
Quitar del manual del lead la seccion `agents/README.md` > `### Lote y espera`
(mecanica de spawn/wait/fork/override), ¿empeora la orquestacion en Codex?

## Brazos
- **A (control):** contrato instalado hoy (`~/.codex/AGENTS.md` -> worktree `53-readonly-cleanup`), copia literal.
- **B:** identico salvo que se elimina `### Lote y espera` (ver `arm-b.patch`, 33 lineas). Se conservan limites, roles, envelope, hallazgos/correcciones y excepciones.

## Entorno (igual en ambos brazos)
- macOS nativo, `codex exec --json` (superficie CLI, multi-agent V2). No se prueba la app ni T3 Code.
- `HOME` y `CODEX_HOME` propios por corrida: `~/agent-scaffolding` resuelve a la copia del brazo; sin contaminacion del repo real.
- Lead: `gpt-6-sol` / `xhigh`. Agentes: los TOML instalados en `~/.codex/agents` (sin cambios).
- Config minima: sin MCP, plugins, hooks, memorias ni web search. `[agents] max_concurrent_threads_per_session = 8`.
- Tarea: solo lectura sobre starlette 1.7.0 (`2269e9a`), 4 preguntas independientes, "delega cada pregunta a un explorer" (prompt.md). Tope duro 45 min por corrida.
- n = 3 por brazo, orden ABBAAB.

## Metricas (del rollout del lead y de los hijos)
Primarias: llamadas del modelo del lead; `wait_agent` totales y con `timed_out`; tokens del lead (input no cacheado + output); reloj.
Secundarias: spawns antes del primer wait / spawns totales; `fork_turns` distinto de `none`; `agent_type` usado; modelo/effort observado en hijos vs ficha; tokens de hijos; KILLED / sin dispatch; calidad (0-2 por pregunta segun referencias verificables, maximo 8).

## Regla de decision
- B **no peor** si la mediana de cada metrica primaria de B <= 1,25 x A y la mediana de calidad de B >= A - 1.
- B **mejor** si ademas alguna primaria <= 0,8 x A.
- Si B falla un dispatch, usa fork o rompe routing en alguna corrida y A no, se reporta como regresion aunque las medianas pasen.
- Con n = 3 es una senal, no una prueba.

## Enmienda 1 (2026-10-06 06:45 UTC, antes del lote 2)
El lote 1 quedo contaminado: el directorio de trabajo colgaba de `~/agent-scaffolding/...`
y 4 de 6 leads leyeron el manual del repo real (`~/agent-scaffolding/agents/README.md`,
que contiene `Lote y espera`) en vez de la copia de su brazo. Dos de las tres corridas B vieron la
seccion eliminada. El lote 1 se conserva como dato observacional, no como comparacion A/B.
Lote 2: mismo diseno, metricas y regla; cada corrida se ejecuta en `/private/tmp/pilot-sinmec/<id>`
(sin `agent-scaffolding` en la ruta de trabajo) y se copia despues a `runs2/`. Se anade un control de
contaminacion: lecturas de `~/agent-scaffolding` y aparicion de "Nunca forkees" en las
salidas del lead.

## Piloto Claude Code (registrado 2026-10-06 ~07:40 UTC, antes de ejecutarlo)
Mismos brazos A/B (con su `CLAUDE.md` -> `@AGENTS.md`), misma tarea (`prompt.md`), n = 3 por brazo, orden ABBAAB.
- Host: Claude Code 2.1.291, `claude -p --output-format stream-json`. Lead `opus` con effortLevel high,
  igual que en tus settings; `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` como en tu config.
- Aislamiento: `HOME` propio por corrida en `/private/tmp/pilot-claude/<id>`, con `~/.claude/CLAUDE.md`
  -> copia del brazo y `~/.claude/agents` = tus fichas generadas. Las credenciales se copian, se
  devuelven si se refrescan y se borran al terminar.
- Permisos: modo por defecto (sin prompts en `-p`), lectura solo del cwd y de `--add-dir` del brazo,
  Bash solo `git status|rev-parse|log`. Leer el repo real queda denegado y se registra.
- Métricas primarias: llamadas del modelo del lead, tokens del lead, coste total (`total_cost_usd`), reloj.
- Métricas secundarias (las específicas de Claude): `subagent_type` usado (ficha propia frente a `Explore`
  built-in), `model` pasado como override en la llamada `Agent` (en Claude el override gana a la ficha),
  modelo observado de cada subagente frente a la ficha, lanzamiento en paralelo (todas las `Agent` en un
  mensaje), `run_in_background`, delegación anidada, denegaciones de permisos y calidad (igual que en Codex).
- Regla de decisión: la misma que en Codex (×1,25 en primarias; calidad ≥ A − 1; cualquier fallo de
  routing presente solo en B cuenta como regresión).

### Enmienda Claude 1 (2026-10-06 08:36 UTC, antes del lote Claude 2)
En el lote Claude 1 las fichas del scaffolding **no estaban disponibles**: con `--setting-sources project,local`
no se cargan las de `~/.claude/agents` (en la sonda parecian cargarse porque las copie como agentes de proyecto).
El lead solo podia usar `Explore`/`general-purpose`. El lote 1 queda como dato observacional ("sin fichas").
Lote 2: mismo diseño, con las fichas copiadas como agentes de proyecto (`<cwd>/.claude/agents`), y la
prueba rapida exige que `explorer-economy` aparezca en la lista de agentes antes de seguir. Salida en `runs2/`.
