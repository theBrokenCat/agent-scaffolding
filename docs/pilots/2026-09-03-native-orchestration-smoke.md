# Smoke nativo de orquestación

Issue: #29. Base congelada: `2bf09b04ab4d2685636270f501acd9b47b14ba80`.

## Pregunta

¿Codex puede lanzar un lote independiente antes de la primera espera, ejecutar
los agentes realmente en paralelo y recoger terminaciones por evento sin el
sondeo corto que dominó la corrida de 38,2 h?

## Diseño

- Lead nativo Codex.
- Cuatro tareas read-only independientes sobre el mismo snapshot.
- `agent_type=explorer-economy`, `fork_context=false`, sin overrides.
- Los cuatro `spawn_agent` se emitieron mediante un único lote antes del primer
  `wait_agent`.
- `wait_agent` recibió siempre el conjunto pendiente y un bound de 60 s; tras
  cada evento se retiró el agente terminal.
- Evidencia de modelo, effort, inicio, fin y tokens tomada de los rollouts hijo.

## Resultados

| Probe | Inicio UTC | Fin UTC | Duración | Modelo | Effort | Cached | Uncached | Output | Reasoning |
|---|---|---|---:|---|---|---:|---:|---:|---:|
| roles | 11:48:57.952 | 11:49:39.007 | 41,055 s | gpt-5.6-luna | high | 126.976 | 42.353 | 1.561 | 858 |
| router | 11:48:58.134 | 11:49:47.829 | 49,695 s | gpt-5.6-luna | high | 118.016 | 9.304 | 1.717 | 1.177 |
| CI/tests | 11:48:58.302 | 11:50:44.934 | 106,632 s | gpt-5.6-luna | high | 415.744 | 75.277 | 4.282 | 2.659 |
| installer | 11:48:58.441 | 11:50:04.517 | 66,076 s | gpt-5.6-luna | high | 169.984 | 16.217 | 2.830 | 1.772 |

Los cuatro spawns comenzaron dentro de una ventana de **0,489 s**. La suma de
duraciones fue 263,458 s; el lote terminó 106,982 s después del primer inicio,
un speedup observado de aproximadamente **2,46×** frente a ejecución serial
idealizada.

| Métrica | Resultado |
|---|---:|
| Agentes del lote | 4 |
| Spawns antes del primer wait | 4/4 |
| Waits | 4 |
| Waits con timeout | 0 |
| Routing correcto | 4/4 |
| Envelopes completos | 4/4 |
| Delegación anidada | 0 |

`wait_agent` no fue una barrera atómica: cada llamada despertó al terminar uno
de los agentes. El patrón válido es un pending-set con waits por evento, no un
único wait-for-all ni polling corto.

## Finding separado

El probe del instalador informó manifests inválidos. Era un falso positivo del
comando ejecutado desde el feature worktree: desde el root canónico, las tres
unidades están sanas; desde el worktree, `source_root` no coincide con el guardado
en el manifest. Se registró en #30 y no invalida el smoke de batching.

## Veredicto

**PASS para batching nativo y espera por evento en este lote acotado.** No prueba
todavía writers concurrentes, paquetes dependientes, SLA de stragglers ni las
reducciones de 38 h a 8–22 h.
