# Mini piloto prospectivo Luna vs Sol

Issue #29. Snapshot de corpus final: `a3e555b`. Este informe no reutiliza las
calibraciones históricas de PenthOX.

## Alcance ejecutado

El smoke nativo pasó y abrió el gate del mini piloto. El spec gate aprobó A;
B y C reabrieron findings por segunda vez y entraron en reset de contrato, por
lo que no se lanzaron implementers para ellos.

| Bloque | Estado |
|---|---|
| A mecánica | pareja economy/frontier ejecutada y aceptada |
| B normal | no ejecutado: segundo reopen del spec |
| C crítica | no ejecutado: segundo reopen del spec |

## Resultado A

Base común: `64d8a32b241b1c81930f4734b53d371aa6a9f822`. Spec hash:
`60455bf0a8326d49992d2bf1caa64b79bd5a6d388ce871e9a5537082027344c8`.
Orden pre-registrado con seed `20260903`: frontier, economy.

| Brazo | Modelo/effort | Tests iniciales | Review #1 | Correcciones | Re-review | Coste hasta aceptado |
|---|---|---:|---|---:|---|---:|
| economy | gpt-5.6-luna/high | 3/3 | pass, 0B/0I | 0 | no necesaria | $0,2104 |
| frontier | gpt-5.6-sol/xhigh | 3/3 | 1 Blocking | 1 | pass, 0B/0I | $1,3690 |

El Blocking de frontier era observable y no estaba cubierto por el oracle
inicial: normalizaba con Unicode `toLowerCase()` antes de validar ASCII, por lo
que el Kelvin sign `K` se convertía en `k` y era aceptado. El reviewer ciego lo
detectó; se añadió una regresión derivada de una cláusula ya congelada, el mismo
owner corrigió el candidato y una re-review independiente pasó. Economy validaba
ASCII antes de transformar y pasó a la primera.

Las implementaciones iniciales fueron distintas. Ambas pasaban el oracle inicial;
solo la review ciega discriminó el defecto.

## Telemetría A

| Agente | Cached | Uncached | Output | Reasoning | Coste API-equivalente |
|---|---:|---:|---:|---:|---:|
| frontier implementer + corrección (mismo owner) | 487.552 | 32.626 | 5.847 | 3.073 | $0,8265 |
| economy implementer | 213.504 | 30.116 | 2.964 | 1.743 | $0,0259 |
| reviewer frontier inicial | 54.784 | 24.097 | 1.367 | 1.066 | $0,2776 |
| reviewer economy | 69.888 | 11.794 | 1.139 | 875 | $0,1844 |
| re-review frontier | 149.504 | 10.739 | 1.982 | 1.271 | $0,2650 |

Frontier costó aproximadamente **6,51×** economy hasta aceptación en esta tarea.
Con n=1 no es una estimación general. Sí demuestra que el coste del reviewer y
de una corrección puede dominar una tarea mecánica que Luna resolvió a la primera.

## Coste de preparar el experimento

| Categoría | Agentes | Coste hijos |
|---|---:|---:|
| smoke read-only | 4 | $0,1092 |
| spec reviews (tres rondas) | 9 | $4,0993 |
| implementación/reviews de A | 5 | $1,5794 |
| reviewer integrado cerrado por SLA | 1 | $1,5390 |
| total | 19 | $7,3269 |

El spec gate evitó gastar implementers en B/C, pero sus tres rondas fueron el
principal coste del ejercicio. Esto no alcanza el objetivo de reducir agentes:
el contrato evitó resultados inválidos, pero el corpus volvió a convertir la
especificación en cuello de botella.

## Esperas

- Smoke: 4 waits, 0 timeouts.
- Spec reviews: 11 waits, 2 timeouts.
- A implementers/reviewers: 7 waits, 2 timeouts.
- Reviewer integrado final: 3 waits, 3 timeouts; cerrado por SLA sin veredicto.
- Total observado: 25 waits, 7 timeouts (28%).

La tasa mejora el 69% de la corrida original, pero no alcanza el objetivo <10%.
Los bounds de 60 s fueron demasiado cortos para implementers y algunos reviewers.

## Veredicto

- **Batching nativo:** pasa en el lote read-only acotado.
- **Economy en tarea mecánica:** pasa este caso y supera a frontier en coste y
  aceptación al primer intento.
- **Balanced normal:** no medido.
- **Gate crítico:** no medido.
- **Reducciones globales de agentes/reloj/coste:** no demostradas.
- **Review final de la PR:** bloqueada por SLA; no hay pass sobre el snapshot.

El resultado práctico es doble: el scaffolding puede paralelizar y esperar por
evento, pero la política de spec/review puede volver a crear el cuello de botella
que el batching elimina.

La rama queda en draft. Suite local y diff-check pasan, pero no puede marcarse
ready ni mergearse sin una review integrada terminal sobre el snapshot final.
