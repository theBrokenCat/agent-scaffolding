# Auditoría crítica: subagentes Codex y agent-scaffolding

> **Corrección (2026-10-06).** Esta auditoría da por medido que un fork (`fork_turns: "all"`) hace que
> el hijo corra con el modelo del padre. Era un artefacto de medición: un rollout forkeado reproduce
> primero la historia del padre, incluido su `turn_context`, y se leyó ese. En los turnos propios del
> hijo (desde `subagent_history_start_ordinal`) los dos rollouts del 2-sep corrieron con su ficha
> (`luna/high` y `luna/max`). En 0.160.1, `fork_turns: "all"` con `agent_type` también se aceptó y corrió.
> Ver `tests/runtime-parity.md` y `docs/pilots/2026-10-06-mecanica-subagentes/`.

Fecha: 2026-09-03. Solo lectura: no se editó ningún archivo del repositorio ni de `~/.codex`.

Etiquetas usadas: **DOC** (documentación oficial OpenAI), **CÓDIGO** (openai/codex en `main`), **OBS** (observado en tu instalación: rollouts de `~/.codex/sessions`, `config.toml`, `~/.codex/agents`), **ISSUE** (reportado en GitHub, no es contrato), **INF** (inferencia mía), **NV** (no verificado).

---

## 1. Veredicto ejecutivo

**Corregir y simplificar, no rediseñar.** El diagnóstico que hizo Codex (spawn en serie, polling, todo en Sol, un agente por microhallazgo) es correcto en lo cualitativo, pero está mal cuantificado y apunta al lever equivocado. Tres hechos que cambian el problema:

1. **De las 38,2 h, 20,4 h fueron espera humana, no de máquina.** El rollout muestra un `task_complete` a las 19:55 UTC del 31/08 y el siguiente turno a las 16:20 UTC del 01/09. El tiempo de máquina real fue ~13,1 h en turnos cerrados más ~4,2 h en dos turnos abortados. El objetivo "38 h → 14–22 h" ya está cumplido sin tocar nada; el objetivo real debería ser "~17 h de máquina → X".
2. **El polling no costó reloj, costó tokens.** Cada `wait_agent` que expira devuelve el control al modelo, que vuelve a razonar con ~390k tokens de contexto. Las 407 esperas explican ~973 llamadas al modelo y los 384M tokens del lead (99,2 % cacheados). Cuando el hijo termina, el `wait` despierta en el acto, así que acortar bounds no acelera nada: solo multiplica llamadas.
3. **El contrato nuevo no ha cambiado la conducta.** En la sesión CLI del 02–03/09 (ya con el contrato v0.2 activo, `codex-cli 0.151.0`): 33 waits, **21 timeouts (64 %)**, bounds empezando en 30 s y subiendo a mano, y spawns en serie salvo un lote inicial de 3. Es prácticamente el mismo patrón del 69 % original. Las reglas en prosa ("espera con bounds largos") no gobiernan al modelo; sí lo hace la configuración del runtime, que hoy no estás usando.

La respuesta a la pregunta central del prompt: **el scaffolding no corrige todavía las causas de las 38 h**. Ha corregido el routing (eso sí está demostrado) y ha desplazado el cuello de botella al spec gate (tres rondas de spec-review costaron 4,10 $ de 7,33 $ en el mini piloto) y a un arnés de medición que ya es más complejo que el problema.

---

## 2. Reconstrucción del "antes" (rollout `2026-08-31T08-23-51`, OBS)

| Métrica | Valor | Evidencia | Confianza |
|---|---:|---|---|
| Reloj total | 38,18 h | primer y último evento del rollout | alta |
| Idle humano (huecos > 20 min sin eventos) | 21,25 h (20,4 h en un solo hueco) | `task_complete` 31/08 19:55Z → `thread_settings_applied` 01/09 16:20Z | alta |
| Tiempo de máquina en turnos cerrados | 13,09 h (turno 2: 12,70 h) | `task_started`/`task_complete` | alta |
| Turnos abortados | 2 (`turn_aborted`), ~4,2 h | eventos | media |
| Subagentes | 19 (14 `worker`, 5 `explorer`; built-ins del host, ningún agente custom) | `spawn_agent` | alta |
| Modelo/effort hijos | 18 × Sol/xhigh, 1 × Sol/max, pasados como override explícito | args de `spawn_agent` | alta |
| Intervalo entre spawns | mediana ~23 min; 7 intervalos > 40 min; uno de 27,8 h (el hueco nocturno) | timestamps | alta |
| `wait_agent` | 407; **267 timeouts (66 %)**; 13,58 h dentro de waits; el 85 % del turno 2 | outputs `timed_out` | alta |
| Bounds pedidos | 60 s ×157, 180 s ×127, 240 s ×106, 120 s ×15, 30 s ×2; máximo 240 s | args | alta |
| Waits que excedieron 1,5× el bound | 0 | duración real vs `timeout_ms` | alta (aquí no hubo stall tipo #24951) |
| Tokens lead | 383,8M input (380,7M cached, 3,1M uncached), 177k output, 69k reasoning; ~973 llamadas ≈ 394k tokens/llamada | último `token_count` | alta |
| Tokens hijos (19) | 363,9M input (357,5M cached, 6,4M uncached), 497k output, 233k reasoning | `token_count` de cada rollout hijo | alta |
| Coste API-equivalente (precio promo Sol 4/0,40/20 $ por 1M, DOC) | lead ≈ 168 $, hijos ≈ 178 $, **total ≈ 347 $**, de los que ≈ 295 $ son lecturas de caché | cálculo | media (los precios son de API; la suscripción no expone equivalencia, NV) |
| Solapamiento real de hijos | máximo 5 abiertos; pero los `explorer` de review quedaron "abiertos" 28–32 h sin trabajar (nunca se cerraron), así que el solapamiento útil fue ≤ 2–3 | spans de rollouts hijo | media |
| Resultado aceptado | no determinable desde rollouts | — | — |

La cifra "279 timeouts / 69 %" del prompt no coincide exactamente con lo medido (267 / 66 %); la diferencia es de conteo, no de fondo. Los "384M tokens" son suma acumulativa por llamada, **no** tokens únicos: es exactamente lo que el prompt pedía comprobar y la respuesta es que ~99 % es contexto reenviado.

**Critical path real:** implementación → spec-review → quality-review → siguiente paquete, con cada hijo en Sol/xhigh tardando 15–735 min, y el lead sin nada que hacer entre medias. El paralelismo disponible era pequeño porque los paquetes eran dependientes. Batching (H1) habría ayudado poco aquí; lo que habría ayudado es (a) no cortar la sesión de noche, (b) hijos más rápidos donde no hacía falta Sol y (c) no pagar 973 llamadas del lead por esperar.

---

## 3. Cómo funcionan realmente los subagentes en TU instalación

Esto es lo que más valor tiene y lo que el prompt de Codex no sabe: **la app y la CLI no exponen la misma superficie de herramientas**, y tu contrato mezcla vocabulario de las dos.

| Aspecto | Codex app (macOS) — OBS sesión `Codex Desktop`, cli 0.152.1 / hijos 0.153.0-alpha.5 | Codex CLI TUI y `codex exec` — OBS 0.150.1 / 0.151.0 con Sol |
|---|---|---|
| Superficie | **Multi-agent V1** expuesta como funciones JS dentro de la celda `exec`: `tools.multi_agent_v1__spawn_agent`, `__wait_agent`, `__close_agent` | **Multi-agent V2** como function calls nativas: `spawn_agent`, `wait_agent`, `list_agents`, `send_message`, `followup_task`, `interrupt_agent` |
| Parámetros de spawn | `agent_type`, `fork_context` (bool), `message`/`items`, `model`, `reasoning_effort` | `task_name` (obligatorio), `agent_type`, `fork_turns` (`"none"`/`"all"`/N), `message`, `model`, `reasoning_effort` |
| Identificador del hijo | `agent_id` + nickname | ruta de tarea `/root/<task_name>` |
| `wait_agent` | acepta `targets` (lista de ids) y devuelve `status` por id + `timed_out` (despierta con el **primero** que termina, CÓDIGO) | **solo** `timeout_ms`; devuelve `{"message":"Wait completed."\|"Wait timed out.","timed_out"}` sin decir quién terminó; despierta por cualquier mensaje de buzón o por steer del usuario (CÓDIGO) |
| Saber quién terminó | del propio `status` del wait | hay que llamar a `list_agents` (por eso tu sesión CLI alterna wait/list_agents) |
| `close_agent` | existe | **no existe en V2** (CÓDIGO: módulos `followup_task, interrupt_agent, list_agents, send_message, spawn, wait`); solo `interrupt_agent` |
| Lote paralelo | un solo `exec` con `Promise.all` lanza N spawns en una llamada del modelo (tu smoke: 4 en 0,489 s) | un function call por spawn: cada spawn cuesta una vuelta del modelo (tu sesión: 3 spawns en 33 s) |
| Coste de esperar | la celda `exec` cede a los ~30 s (`yield_time_ms`) y el modelo debe llamar a `wait(cell_id)` hasta que la promesa resuelva: **cada 30 s de espera es una llamada del modelo**, aunque el `timeout_ms` del wait sea largo | una llamada del modelo por wait, hasta 3600 s (CÓDIGO `max_wait_timeout_ms`) |
| Mensajes en rollout | legibles | cifrados (`gAAAA…`, changelog 0.138) — tu arnés solo puede leer el brief en el rollout del hijo |
| Versión | la app actualiza sola (alpha bundled); hoy 0.153.0-alpha.5 | la que instalaste: 0.151.0 (última publicada 0.153.0, 2026-09-03) |

Consecuencias directas:

- El contrato dice "pending-set y `close_agent`". En CLI no hay `targets` ni `close_agent`; el pending-set solo existe en la cabeza del lead y se reconstruye con `list_agents`. En la app sí existen ambos. **Hay que escribir el protocolo por superficie, no uno genérico.**
- "Nunca `fork_turns: "all"`" es V2; en la app el parámetro es `fork_context`. Tus propios docs mezclan ambos (`fork_context=false` en el smoke, `fork_turns: "none"` en parity).
- El "speedup 2,46×" del smoke es real pero pequeño y **solo reproducible en la app** (`Promise.all`); en CLI el lote es serial por construcción del protocolo, aunque los hijos sí corren en paralelo después.
- Issue #37113 (Sol confunde `wait` de celda con `wait_agent`) es exactamente la ambigüedad que tu app tiene: dos herramientas llamadas `wait`. En tus rollouts de app aparecen 17 llamadas a `wait` (de celda) para recoger `wait_agent`; no hubo confusión visible, pero el riesgo existe.

### Límites y comportamientos verificados

| Pregunta del prompt | Respuesta | Etiqueta |
|---|---|---|
| Parámetros reales de `spawn_agent` | V1: `message, items, agent_type, fork_context, model, reasoning_effort`. V2: `message, task_name, agent_type, fork_turns, model, reasoning_effort` (`fork_context` también aceptado por el handler V2 con `deny_unknown_fields`) | CÓDIGO |
| ¿Custom agent gana al override? | Sí: el handler aplica primero `model`/`reasoning_effort` pedidos y **después** la capa del rol, que "preserva el modelo/effort del llamante salvo que la capa del rol los fije". Tu parity lo observó (4 escalados por override corrieron en el par base). No hay error ni aviso | CÓDIGO + OBS |
| ¿Fork anula el alias? | Sí: con full-history fork el hijo hereda el `agent_type` del padre y el handler rechaza `agent_type` + fork completo ("Full-history forked agents inherit the parent agent type"). En tu control, un agente Luna/max forkeado corrió en Sol/xhigh | CÓDIGO + OBS |
| ¿Qué hereda el hijo? | Config clonada del turno padre: modelo/effort del padre salvo override o rol, cwd, sandbox, approval policy, permission profile, service tier (0.152: "subagents follow the root service tier"), MCP y skills salvo que el TOML los cambie. Sin fork: solo el prompt inicial y las developer_instructions del rol. `AGENTS.md`: no documentado si el hijo lo relee (INF: mismo cwd → mismas instrucciones) | DOC + CÓDIGO / NV |
| ¿Nested spawn? | V1: `agents.max_depth` (default 1) lo impide con error "Agent depth limit reached". V2: `max_depth` "ignored by V2"; el prompt oficial dice literalmente que debes decirle al hijo que no puede spawnear | CÓDIGO + DOC |
| ¿Ocupan slot los terminados? | V1: sí hasta `close_agent` (registro decrementa solo al cerrar; issues #22779/#18335). V2 en tu instalación: la sesión del 02–03/09 lanzó 14 agentes con hasta 11 terminados sin cerrar y **ningún** error de límite, así que o no cuentan o el cap efectivo es ≥ 14 | CÓDIGO / OBS / NV |
| ¿Cómo se calcula el cap de 8? | Tienes `[agents] max_concurrent_threads_per_session = 8`. DOC actual: "excluyendo el primario". CÓDIGO V2: `max_concurrent_threads_per_session.saturating_sub(1)` (el root cuenta). En la app (V1) manda `agents.max_threads` (default 6). **No sé si tu 8 son 7 u 8 hijos, ni si aplica en la app**; es una prueba de 5 minutos: lanza 8 explorers triviales y mira si el 8.º falla | DOC vs CÓDIGO, NV |
| `wait_agent`: bounds | V2: default 30 s, **mínimo 10 s (se clampa hacia arriba), máximo 3600 s (error si lo superas)**; los tres son configurables en `[features.multi_agent_v2]`. V1 (app): `clamp(10 s, 3600 s)`, default 30 s | CÓDIGO |
| Estados terminales | `Completed`, `Errored`, `Shutdown`, `NotFound`; no terminales `PendingInit`, `Running`, `Interrupted` | CÓDIGO |
| Timeout no respetado (#24951) | Abierto, Desktop/Windows, mayo. En los 440 waits revisados (407 del antes + 33 de la sesión CLI del 03/09) ninguno excedió claramente su bound. No aplica a tu evidencia | ISSUE / OBS |
| `codex exec` con subagentes | #33267 (0.144.4) decía roto en V2; en tu 0.151.0 el arnés lanzó 4–5 hijos por `codex exec` y los rollouts hijo existen. Aplica con cautela: el padre `exec` terminó a los ~50 s sin esperar a los hijos en dos de las tres sesiones | ISSUE / OBS |
| Sol/Terra no pueden lanzar Luna (#34301) | Refutado en tu instalación: Sol lanza `explorer-economy` en Luna/high sin problema | OBS |
| Bugs de "Sol emite `wait` en vez de `spawn_agent`" (#35541/#35620/#37113) | Abiertos, julio–agosto, todos Windows/Desktop con Sol. En tus rollouts no aparece el patrón `spawn → wait(dummy)`. No hay fix referenciado | ISSUE |
| Cuánto crédito consumen los subagentes | DOC: todo Codex comparte "the same agentic usage and credit pool"; no hay tarifa documentada para cached input en créditos ni equivalencia oficial vigente entre créditos y dólares (la de 40 $/1000 es de un post de X de 2025) | DOC / NV |

---

## 4. Evaluación del prompt de Codex

Lo bueno: la jerarquía de evidencia, el etiquetado obligatorio, la exigencia de leer rollouts y no aceptar los números de la documentación, la lista de fuentes iniciales (todas correctas y relevantes), y la pregunta central bien formulada. Es un prompt de auditoría serio.

Lo que le sobra o está mal planteado:

1. **Es demasiado grande para un solo agente.** Pide 20 salidas, tabla archivo por archivo, comparación de 5 arquitecturas, forense completa, protocolo con pseudocódigo y un contrato listo para copiar. Un Sol/xhigh con un contexto de 800k va a producir un documento largo cuya mitad no podrá verificar, y tú no vas a poder auditar la auditoría. Divídelo en tres prompts: (a) forense del antes + funcionamiento real por superficie (lo que hay arriba), (b) auditoría del contrato con esa evidencia, (c) propuesta de protocolo por host.
2. **Asume que 38,2 h es tiempo de máquina.** La sección "reconstruye el antes" pide "tiempo con 0/1/2–3 agentes activos" pero no pide separar idle humano de idle de máquina. Añade explícitamente: "separa huecos entre `task_complete` y el siguiente turno; el reloj de máquina es la suma de turnos".
3. **No distingue app de CLI**, que es la diferencia que más importa en tu caso (V1 vía celda `exec` con `Promise.all` frente a V2 nativo sin `targets` ni `close_agent`). Pregunta por `codex exec`, JSON experimental y "threads de la app", pero no por la celda `exec` de la app, que es donde realmente se orquesta.
4. **Pide investigar `close_agent`, `resume_agent` y `send_input` como si existieran siempre.** En V2 no existen; existen `interrupt_agent`, `send_message`, `followup_task`, `list_agents`. Si el auditor lo toma literal, concluirá cosas de V1 y las aplicará a tu CLI.
5. **Prohíbe lanzar pruebas** ("no lances pilotos ni implementers") pero pide respuestas que solo una prueba de 5 minutos da (cap 7 vs 8, slots de terminados en V2, `yield_time_ms` máximo de la celda). Autoriza explícitamente "probes read-only de ≤ 1 min con `explorer-economy`", que es lo que ya hiciste en el smoke.
6. **Sesgo en el mapa de modelos.** Afirma que Terra "está dominada en Pareto en todos los niveles de effort" sin dato; la documentación oficial actual recomienda `gpt-5.6-terra` precisamente para "exploración, escaneos read-heavy y revisión de archivos grandes" y Luna para trabajo "estrecho y de alto volumen". El prompt pide "no recomiendes Terra sin evidencia emparejada", pero tampoco tiene evidencia emparejada para excluirla. Pide evidencia para las dos.
7. **Mezcla la métrica.** Insiste en "coste hasta 0B/0I" (bien) pero luego pide "coste API-equivalente por lead/implementers/reviewers" cuando pagas suscripción; lo útil para ti son **llamadas al modelo** (cada una reenvía el contexto) y **tokens no cacheados + output**, que sí mueven límites de 5 h/semana. Pide esas dos y trata el dólar como referencia secundaria.
8. **Sobrecarga de "no hagas"**: hay más reglas de honestidad que preguntas. Están bien, pero muchas ya las cumple un modelo con la jerarquía de evidencia; recorta.
9. **Faltan preguntas de runtime que sí resuelven el problema:** configuración de `min_wait_timeout_ms`/`default_wait_timeout_ms`, `hide_spawn_agent_metadata`, `sandbox_mode` por agente, y qué pasa al reanudar una sesión con hijos abiertos (changelog 0.139 "avoid reopening v2 descendants on resume"). El prompt está centrado en el contrato (prosa) y el lever real está en `config.toml`.

---

## 5. Evaluación del diseño actual del scaffolding

### Lo que está bien y demostrado

- Routing por nombre con un archivo por estado (`<rol>-<estado>`) y prohibición de escalar por override: correcto, coherente con el código y verificado en los nueve estados. Es el mejor hallazgo del trabajo.
- Prohibir el fork cuando el alias importa: correcto y con control experimental.
- Medir modelo/effort del rollout hijo por `parent_thread_id`, no del padre ni del self-report: correcto.
- Leer coste del hijo y no del padre: correcto.
- El envelope compacto y "no adjuntes logs": correcto y barato.
- Reset de contrato a la segunda reapertura, SLA de reviewer, revisión final integrada: buenas reglas de proceso.

### Lo frágil, incorrecto u optimista

| Sev. | Dónde | Problema | Evidencia | Corrección |
|---|---|---|---|---|
| Alta | `agents/README.md` §Lote y espera, `policies/README.md`, `AGENTS.md` §4 | "Espera con bounds largos" no se cumple: el lead elige 30–240 s por defecto en ambas superficies (sesión CLI 03/09: 64 % timeouts; mini piloto app: 28 %, todos a 60 s) | rollouts | Enforce en runtime: `[features.multi_agent_v2] min_wait_timeout_ms = 300000` y `default_wait_timeout_ms = 900000` en `config.toml` (el runtime clampa hacia arriba; CÓDIGO). En la app, además, pedir en el brief que el `wait_agent` vaya dentro de una celda con el `yield_time_ms` máximo que admita (probar 300000; NV) |
| Alta | contrato entero | Habla de `close_agent`, "retira terminales y ciérralos" y `fork_turns` como si hubiera una sola superficie; en CLI V2 no hay `close_agent` ni `targets`; en app no hay `fork_turns` | OBS | Un bloque "Protocolo por superficie" con dos variantes cortas (ver §7) y detección al inicio: "si existe `tools.multi_agent_v1__wait_agent` → app/V1; si `wait_agent` solo acepta `timeout_ms` → V2" |
| Alta | `docs/pilots/2026-09-02…`, `tasks/todo.md`, prompt | Baseline de 38 h usada como tiempo de máquina | rollout | Reescribir baseline: 13,1 h de turnos + 4,2 h abortadas + 20,4 h idle humano. Objetivo de reloj sobre ~17 h, no sobre 38 |
| Alta | `agents/README.md` §Mecanismos, `policies` | "8 simultáneos, 3 writers" asume que 8 es lo que expone el host. En V2 el código resta 1 (root); en app V1 manda `agents.max_threads` (default 6); la doc dice "excluyendo el primario" | DOC vs CÓDIGO | Probar el cap real por superficie (8 explorers triviales) y escribir el número medido. Mientras, "7" es la cifra segura |
| Alta | `scripts/gen-agents` `render_codex` | No emite `sandbox_mode`. Los roles read-only (explorer, spec-reviewer, quality-reviewer) solo son read-only por prosa; el host permite `sandbox_mode = "read-only"` por agente | DOC + archivo generado | Emitir `sandbox_mode = "read-only"` cuando `authority: read-only`. Ojo: un reviewer que necesita ejecutar tests puede fallar en read-only; deja `quality-reviewer` en `workspace-write` si ejecuta suites, o dale un worktree propio |
| Media | mini piloto (`2026-09-03-mini-pilot-results.md`) | El spec gate (9 agentes Sol, 3 rondas, 4,10 $) fue el 56 % del coste; B y C entraron en reset sin implementar. El contrato desplazó el cuello de botella a la especificación, que es justo lo que la pregunta central temía | tu propio informe | Spec-review una sola ronda en `frontier/high`; si reabre, el lead corrige la spec y lanza **una** re-review, no tres rondas de tres agentes. Para tareas `economy` (mecánicas), sin spec-review: el oracle es la spec |
| Media | `ROUTER.md` §curvas, `profiles` | "Terra dominada en Pareto" es una afirmación sin dato emparejado; la doc oficial la recomienda para exploración read-heavy y archivos grandes | DOC | O aportas el benchmark, o Terra entra como candidato de `explorer-balanced` en el piloto |
| Media | mini piloto | "Economy 6,5× más barato que frontier" con n=1 y con el Blocking de frontier descubierto por un reviewer ciego que economy no recibió con la misma dureza (reviewer economy costó 0,18 $ vs 0,28 $ del frontier: distinto reviewer, distinto coste, no ciego al brazo por coste) | informe | Mismo reviewer (mismo estado) para todos los brazos; n≥5 por bloque antes de sacar ratios |
| Media | `docs/pilots/2026-09-03-native-orchestration-smoke.md` | "speedup 2,46×" compara con serial idealizado y con probes de 40–107 s. No prueba nada sobre writers ni dependencias (el informe lo admite). Vale como smoke de mecanismo, no como dato de reloj | informe | Mantener como smoke; no citarlo en objetivos |
| Media | `~/.codex/agents/luna_max.toml` | Agente residual fuera del generador y del manifest; Luna/max no es un estado del contrato | OBS | Retirar o adoptar en el model map |
| Media | contrato "Terminales ocupan slot hasta cerrar" | En V2 no se puede cerrar; en tu sesión 11 terminados sin cerrar no bloquearon el spawn 12–14. No se sabe si es porque no cuentan o porque el cap efectivo es mayor | OBS / NV | Medir (prueba de cap) y reescribir |
| Media | `AGENTS.md` §4 y `policies` | Regla "spawnea todo el lote antes del primer wait" en CLI cuesta una vuelta del modelo por spawn (~10–20 s cada una, ~400k tokens cacheados cada una). Aceptable, pero el contrato debería decir que la unidad cara es la **llamada del modelo**, y que el lead no debe insertar `list_agents` entre spawns | OBS | Añadir a la política: "una llamada = ~contexto completo; minimiza llamadas del lead, no segundos de espera" |
| Media | `pilot-run --max-seconds` | Mata `codex exec` al expirar, pero un padre `codex exec` puede terminar antes que sus hijos (dos sesiones del 02/09 acaban a los ~50 s con 4–5 spawns y 0–1 wait). Fila "medida" con hijos huérfanos | OBS | El arnés debe esperar el `task_complete` del hijo (rollout hijo), no el exit del padre |
| Baja | contrato | `interrupt_agent` con `target_header`/`message` falló por parámetros inventados en tu sesión; el modelo tantea schemas | OBS | Incluir en el protocolo la firma exacta por superficie |
| Baja | `README.md`, `runtime-smoke.md` | Versiones observadas (0.144.3) desfasadas; app y CLI van a versiones distintas y cambian defaults (`hide_spawn_agent_metadata`, V1/V2 por modelo) | OBS | `doctor` debería registrar `cli_version` del último rollout y la superficie detectada |
| Baja | `agents.max_concurrent_threads_per_session` | Si algún día V2 se activa por feature y no por modelo, `agents.max_threads` se rechaza (#33447) y el cap pasa a `[features.multi_agent_v2]`. Hoy no te afecta | ISSUE | Pinear también `[features.multi_agent_v2] max_concurrent_threads_per_session = 8` y `hide_spawn_agent_metadata = false` para que una actualización no te esconda `agent_type` (#31814) |

### Hipótesis H1–H8

| Hipótesis | Baseline | Evidencia nueva | Veredicto | Qué falta |
|---|---|---|---|---|
| H1 Batching reduce reloj | spawns cada 18 min (mediana) | smoke: 4 lecturas en paralelo, 2,46× sobre serial ideal; en CLI el lote es serial por vuelta | **Parcial**: funciona, pero el reloj del antes lo dominaban dependencias e idle, no spawn serial | Un paquete real con ≥3 scopes independientes medido en la app |
| H2 Espera por evento reduce waits/timeouts | 407 / 66 % | app 25/28 %; CLI 33/64 % | **Refutada como está** (prosa); **plausible** con `min_wait_timeout_ms` en config | Aplicar config y repetir |
| H3 Luna baja coste sin escapar defectos | todo Sol | A mecánica: economy 0,21 $ vs frontier 1,37 $ (n=1) | **No medida** (n=1, reviewers distintos) | n≥5 por bloque, mismo reviewer |
| H4 Sol en seams críticos conserva calidad | — | C no ejecutado | **No medida** | Bloque C |
| H5 Correcciones agrupadas | ~1 agente/finding | mini piloto: 1 lote por owner funcionó en A | **Parcial** | Paquete con >1 finding |
| H6 Lead delega evidencia read-only | lead hacía todo | explorers economy devuelven envelope útil | **Confirmada** en lo mecánico | — |
| H7 8 total / 3 writers | 3 workers | nunca se han lanzado 8 ni 3 writers | **No medida** | Prueba de cap; 2–3 writers en worktrees |
| H8 Envelopes compactos | logs completos | envelopes respetados 4/4 | **Confirmada** parcialmente; el lead sigue a 400–550k tokens de contexto por su propio historial | Compactar/forkear sesión del lead por paquete |

---

## 6. Recomendaciones por impacto

1. **Configura el runtime, no solo el contrato** (`~/.codex/config.toml`):
   ```toml
   [features.multi_agent_v2]
   min_wait_timeout_ms = 300000      # el runtime clampa hacia arriba: adiós waits de 30 s en CLI
   default_wait_timeout_ms = 900000
   max_concurrent_threads_per_session = 8
   hide_spawn_agent_metadata = false # que una actualización no esconda agent_type
   ```
   Verifica después con un wait de 30 s pedido y mide que dura ≥ 300 s (o que la respuesta incluye la nota de clamp). Etiqueta: CÓDIGO para la semántica, NV para tu versión concreta hasta que lo pruebes. En la app (V1) esto no aplica al `wait_agent` de la celda; ahí la unidad es el `yield_time_ms` de `exec`/`wait`: prueba cuál es el máximo.
2. **Reescribe la baseline y los objetivos** con 17 h de máquina y 973 llamadas del lead como referencia. Métricas que mandan: llamadas del modelo del lead por paquete, tokens no cacheados + output totales (lead + hijos), reloj de máquina (suma de turnos), defectos escapados. Reloj de pared solo si la sesión no se corta.
3. **Protocolo por superficie** en `agents/README.md` (borrador en §7). Detección al inicio del turno y dos bucles distintos.
4. **Reviewers**: spec-review una ronda, solo en `standard`/`deep`; quality-review integrada una vez por snapshot; re-review solo del diff de corrección. Las tres rondas de spec gate son el nuevo cuello de botella y el propio informe lo dice.
5. **`sandbox_mode = "read-only"`** generado para roles read-only (explorer y spec-reviewer seguro; quality-reviewer según ejecute tests). Es la única forma de que "authority: read-only" sea una garantía y no una frase.
6. **Cap real medido**: 8 explorers triviales en cada superficie; anota el número en `runtime-parity.md`. Hasta entonces el contrato debería decir 7.
7. **No cortes la sesión**: el hueco de 20 h fue humano. Si un paquete va a durar horas, o lo lanzas antes de irte con un STOP claro al final del turno, o aceptas que el reloj de pared no es la métrica.
8. **Hijos más cortos, no más hijos**: los cuatro `worker` Sol/xhigh grandes del antes duraron 134–735 min con 11–41 llamadas y 53–86M tokens acumulados cada uno. Eso es un implementer haciendo un paquete entero. Divide el scope del implementer para que cada despacho cierre en < 30 min, y deja la integración al lead. Reduce reloj (paralelizable) y coste (menos contexto por llamada del hijo).
9. **Terra al piloto** como brazo de `explorer-balanced` (doc oficial la recomienda para eso). Si pierde, lo documentas con dato.
10. **Simplifica el arnés**: `pilot-run` + `pilot-report` + tests del arnés ya superan en tamaño al contrato. Un paquete real medido con tres números (llamadas del lead, uncached+output, defectos escapados) vale más que otra iteración del harness. La pregunta del prompt "no recomiendes más hardening si no corrige una causa" se aplica a ti.

Sobre las cinco arquitecturas: **A (lead Codex nativo + custom agents)** es la correcta para tu caso, con dos matices: en la app el lead ya es "B" a medias (orquesta desde JS con `Promise.all`, que es determinista y barato en llamadas); y **C (Claude lanzando `codex exec`)** ya la usaste para el parity y tiene el problema de que el padre `exec` no espera a los hijos. B pura (orquestador externo) te daría waits gratis y logs legibles, pero pierdes la app, el steer y los custom agents; no compensa hasta que A con config corregida demuestre que sigue polling. D (sin subagentes salvo reviewers) es lo que de facto hiciste en el antes y costó 17 h de máquina; E (waves adaptativas) es A con una regla simple: lanza la wave completa de scopes independientes, y la wave siguiente solo cuando `list_agents`/`status` diga que toda la anterior es terminal.

Política adaptativa mínima (INF, sin más datos): 1 agente si el scope es único o dependiente; 2–4 solo con scopes independientes y paths disjuntos; 5–8 únicamente readers (explorers/reviewers) sobre snapshot congelado; secuencial cuando el siguiente scope depende del resultado del anterior; straggler = supera 2× la mediana de sus hermanos → `interrupt_agent` + relanzar con scope recortado, nunca esperar otra ronda.

---

## 7. Borrador de protocolo por superficie (para `agents/README.md`, no aplicado)

```text
Detección (una vez por turno):
  si existe tools.multi_agent_v1__wait_agent (celda exec)       -> SUPERFICIE = app/V1
  si spawn_agent exige task_name y wait_agent solo timeout_ms   -> SUPERFICIE = cli/V2
  si ninguna                                                    -> sin delegación; app-direct

app/V1 (celda exec, ids):
  ids = Promise.all(lote.map(spawn_agent{agent_type, fork_context:false, message}))
  pendientes = set(ids)
  mientras pendientes:
    r = wait_agent{targets:[...pendientes], timeout_ms: BOUND}   # BOUND >= 600000
    si la celda cede: wait{cell_id, yield_time_ms: MAX_YIELD}    # una sola llamada por ceder
    para id,estado en r.status: procesar envelope; pendientes -= {id}; close_agent{target:id}
    si r.timed_out y sin cambio: aplicar SLA (interrupt/relanzar), no acortar BOUND

cli/V2 (function calls, rutas):
  para cada scope: spawn_agent{task_name, agent_type, fork_turns:"none", message}  # sin list_agents entre spawns
  pendientes = set(rutas)
  mientras pendientes:
    r = wait_agent{timeout_ms: BOUND}                              # BOUND >= 600000; el runtime clampa al mínimo configurado
    a = list_agents{}                                              # una sola vez por despertar
    para ruta en pendientes con estado terminal en a: procesar; pendientes -= {ruta}
    si r.timed_out y sin cambio: SLA; no acortar BOUND
  no hay close_agent: un agente terminal se abandona; interrupt_agent solo para stragglers

Ambas:
  - hijos no delegan (dilo en el brief; en V2 no hay max_depth)
  - nunca fork cuando el alias importe (fork_context:true / fork_turns:"all")
  - escalar = despachar <rol>-<estado>, nunca model/reasoning_effort con agent_type
  - la unidad de coste del lead es la llamada al modelo: sin list_agents redundantes, sin razonar tras un timeout sin cambio
```

---

## 8. MEDIDO / INFERIDO / NO VERIFICADO

**Medido (OBS):** 38,18 h de reloj con 20,4 h de hueco humano; 13,09 h de turnos cerrados; 19 hijos Sol; 407 waits / 267 timeouts; 13,58 h en waits; 384M tokens lead (380,7M cached) en ~973 llamadas; 364M tokens hijos; sesión CLI 03/09 con contrato v0.2: 33 waits / 21 timeouts, 91M tokens lead; app usa `multi_agent_v1__*` vía celda `exec` con `Promise.all`; CLI 0.151.0 usa V2 con mensajes cifrados; custom agents ganan al override; fork anula alias; Sol lanza Luna; `[agents] max_concurrent_threads_per_session = 8` en config; sin `sandbox_mode` en los TOML generados; `luna_max.toml` residual; app en 0.153.0-alpha.5 y CLI en 0.151.0.

**Inferido (INF):** que el 20 % del coste API-equivalente de los hijos también es polling interno (no medido por hijo); que en V2 los terminados no ocupan slot (o el cap no se enforce) porque 14 spawns con 11 terminados no fallaron; que `AGENTS.md` se aplica al hijo por compartir cwd; que la política adaptativa propuesta funciona.

**No verificado (NV):** si tu 8 son 7 u 8 hijos y si rige en la app; `yield_time_ms` máximo de la celda `exec`; si `min_wait_timeout_ms` en `[features.multi_agent_v2]` se honra cuando V2 viene seleccionado por modelo (issue #33447 sugiere que sí para el cap); equivalencia créditos↔dólares vigente y tarifa de cached input en créditos; estado actual de PR #27–#31 (sin acceso a GitHub desde esta sesión; el rollout muestra PR #31 como draft editada el 03/09); si los issues #24951/#34653/#35541/#35620/#37113 tienen fix (siguen abiertos, sin PR enlazada); si Terra está dominada en Pareto.

---

## 9. Fuentes

- Docs subagentes: https://developers.openai.com/codex/subagents (redirige a https://learn.chatgpt.com/codex/agent-configuration/subagents)
- Config reference: https://developers.openai.com/codex/config-reference
- Modelos y precios: https://developers.openai.com/api/docs/models · https://developers.openai.com/api/docs/models/gpt-5.6-sol · https://learn.chatgpt.com/docs/pricing · https://help.openai.com/en/articles/20001106-codex-rate-card
- Código: `codex-rs/core/src/tools/handlers/multi_agents_spec.rs`, `multi_agents/spawn.rs`, `multi_agents/wait.rs`, `multi_agents_v2.rs`, `multi_agents_v2/spawn.rs`, `multi_agents_v2/wait.rs`, `multi_agents_common.rs`, `agent/status.rs`, `agent/registry.rs`, `config/mod.rs`, `features/src/lib.rs`, `features/src/feature_configs.rs`, `templates/collab/experimental_prompt.md` en https://github.com/openai/codex
- Releases: https://github.com/openai/codex/releases (rust-v0.153.0, 2026-09-03) · changelog https://learn.chatgpt.com/docs/changelog?type=codex-cli
- Issues: #24951, #26822, #34653, #34919, #35541, #35620, #37113, #22779, #18335, #33447, #31814, #31097, #24704, #24150, #33267, #34301, #35984; PRs #19792, #20052, #26599, #28341
- Local: `~/.codex/config.toml`, `~/.codex/agents/*.toml`, `~/.codex/sessions/2026/08/31/rollout-2026-08-31T08-23-51-*.jsonl` (38 h), `~/.codex/sessions/2026/09/03/rollout-2026-09-03T00-52-33-*.jsonl` (CLI, contrato v0.2), `~/.codex/sessions/2026/09/03/rollout-2026-09-03T00-47-41-*.jsonl` (app, smoke + mini piloto), repo `~/agent-scaffolding` y worktrees 26/28/29.
