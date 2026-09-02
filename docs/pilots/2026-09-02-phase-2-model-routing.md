# Piloto v0.2: routing de modelos y orquestacion (cierre)

Diseno del piloto que debe validar —o refutar— el routing de la fase 2. Se
registra **antes** de ejecutarlo: los criterios de abajo estan pre-registrados y
no se reinterpretan despues de ver los numeros. El cierre historico no es un
piloto final de 14 filas: es un piloto inconcluso/abortado por corpus inválido.

## Objetivos

Son un **stretch**, no una promesa. El baseline defendible es la cifra que hay
que defender ante un revisor; el techo es lo que el diseno permite si todo sale
bien.

| Magnitud | Punto de partida | Baseline defendible | Techo (stretch) |
| --- | --- | --- | --- |
| Agentes por paquete | 19 | 8-11 | 8 |
| Reloj por paquete | 38 h | 14-22 h | 8-12 h |
| Coste | referencia | -40 % a -65 % | -70 % a -85 % |

La metrica que manda es **el coste hasta el resultado aceptado**, no el del
primer turno. Un turno barato que necesita tres correcciones y una reapertura de
diseno es mas caro que uno caro que cierra a la primera; medir solo el primer
turno favorece exactamente al brazo equivocado.

## Diseno

A/B **emparejado**: cada tarea se ejecuta en todos los brazos.

- Mismo SHA base, mismo prompt, mismas herramientas y mismos criterios de
  aceptacion en cada brazo.
- Orden de brazos aleatorio por tarea, para que el aprendizaje del operador no se
  acumule siempre sobre el mismo.
- El reviewer es Sol y va **ciego al modelo** que produjo el resultado. Si el
  reviewer sabe que brazo evalua, el resultado no es un dato.
- Un brazo no se descarta por una tarea: se descarta por bloque.

### Brazos

| Brazo | Alias equivalente | Papel |
| --- | --- | --- |
| Luna High | `economy` | candidato barato |
| Luna XHigh | `balanced` | candidato por defecto |
| Terra High | escalon diagnostico | opcional; solo para separar "fallo por capacidad" de "fallo el brief" |

Terra no compite: entra unicamente cuando un fallo de Luna necesita diagnostico.

### Bloques

| Bloque | n | Que mide |
| --- | --- | --- |
| Tareas mecanicas | 10-20 | si `economy` basta donde el trabajo esta totalmente especificado |
| Exploraciones multiarchivo | 10 | el escalon `economy` -> `balanced` del `explorer` |
| Implementaciones con contrato congelado | 10 | el default de `implementer` |
| Horizonte largo | 3 (minimo 1) | donde mas te juegas: el gate de "cuanto dura" |

### El bloque de horizonte largo es asimetrico

No produce una media y no se convierte en porcentaje: informa el juicio. Pero su
evidencia **no pesa igual en las dos direcciones**, y esa asimetria se
pre-registra como regla de decision:

- **Un solo fallo de un brazo sub-frontier en horizonte largo CONFIRMA el gate.**
  Basta uno. Ese brazo queda descartado para horizonte largo y no se le da otra
  oportunidad dentro del piloto.
- **Un exito, o incluso tres, NO refutan el gate.** Ausencia de fallo con n = 3 es
  ausencia de evidencia, no evidencia de ausencia: el modo de fallo que motiva el
  gate aparece en runs largos y es intermitente.

Es decir: el bloque solo puede mover la decision en un sentido. Si sale limpio,
el gate sigue en pie por la evidencia previa —modelos sub-frontier que en runs de
100+ tareas caen a 40,7 % de aciertos frente a 63,7 %, quemando 2,65x tokens— y
`frontier` sigue siendo el default de horizonte largo.

Sube a n = 3 si el coste lo permite; con n = 1 la regla es la misma, solo que la
probabilidad de observar el fallo baja. Nunca reportes este bloque como "X % de
exito".

## Que se mide en cada ejecucion

- Aceptacion en primer intento (si / no).
- Hallazgos `Blocking` e `Important` **encontrados**, y los **escapados** hasta la
  revision final.
- Numero de correcciones y numero de lotes de correccion.
- Tokens: cacheados, no cacheados, de salida y de reasoning, por separado.
- Creditos consumidos.
- Tiempo de reloj, de principio a resultado aceptado.
- Fallos de herramienta y timeouts de espera.
- **Coste hasta 0 Blocking / 0 Important**, que es el numero que decide.

## Criterios pre-registrados

Un brazo pasa solo si cumple todos:

1. Sin aumento de `Blocking` o `Important` **escapados** frente al brazo de
   referencia.
2. Cero regresiones criticas.
3. Timeouts de espera por debajo del 10 % de las esperas.
4. Como maximo 2 lotes de correccion por paquete.
5. Como maximo 1 reapertura del mismo seam antes de que aplique el reset de
   diseno.
6. Al menos 50 % menos de reloj en mediana.
7. Al menos 50 % menos de coste en mediana.
8. Al menos 60 % menos de tokens no cacheados mas reasoning.
9. Sin conflictos entre writers y sin gates amplios invalidados.

Los criterios 1 y 2 son eliminatorios: un brazo mas barato que deja escapar mas
defectos no es mas barato, solo mueve el coste a otro sitio.

## Arnes de medicion

`scripts/pilot-run` produce las filas. Medir 31-41 ejecuciones a mano corrompe
los datos, asi que el arnes rellena todo lo que una maquina puede observar
—tokens cacheados y no cacheados, salida, reasoning, reloj, fallos de
herramienta— y lee el **modelo y effort realmente usados** del rollout de sesion,
nunca del informe del propio modelo.

Las columnas de juicio (aceptacion, Blocking/Important encontrados y escapados,
correcciones, lotes, creditos, coste hasta aceptado) las deja **vacias a
proposito**: las rellena el reviewer ciego. Un arnes que las adivinara corromperia
justo el dato que el piloto existe para recoger.

```sh
scripts/pilot-run dispatch --task T1 --block mecanicas --arm balanced \
  --agent-type implementer-balanced --prompt wrapper.txt --brief brief.txt \
  --attempts runtime/pilot-v0.3 --kind implementation \
  --cwd /ruta/al/worktree --max-seconds 1800
scripts/pilot-run record --attempts runtime/pilot-v0.3 --task T1 \
  --arm balanced --kind implementation --attempt 1 \
  --field reviewer_id --value reviewer-blind-01
scripts/pilot-run spent --attempts runtime/pilot-v0.3 \
  --ceiling 32.25 --reserve "$NEXT_DISPATCH_USD"
scripts/pilot-report runtime/pilot-v0.3 > resultados.tsv
```

`record` solo admite `accepted`, `blocking`, `important`, `corrections`,
`reviewer_id`, `adjudicator_id` y `failure_detail`; no puede reescribir modelo,
tokens, costes, hashes ni IDs de hilo. Los campos de juicio deben registrarse
explicitamente antes del informe. `adjudicator_id` lleva el ID real cuando hubo
adjudicacion y `-` cuando no aplicaba.

`reviewer_id` es singular y debe coincidir con el `child_thread_id` de al menos
un artefacto `review`; si hay varios intentos de review, todos deben pertenecer a
ese mismo ID. Un `adjudicator_id` distinto de `-` exige el mismo enlace con
artefactos `adjudication`. Sin esos enlaces la fila se excluye, y el coste de
review suma tambien la adjudicacion enlazada.

El techo historico autorizado fue `$40`; v0.2 consumio `$7.7491`. v0.3 usa un
maximo adicional redondeado de `$32.25`, comprobado antes de cada despacho con
`spent --ceiling 32.25 --reserve N`. La parte reservada para D se lleva fuera del
arnes: para despachos no-D el operador reduce el `ceiling` por esa reserva; el
arnes no inventa una estimacion por bloque.

`--max-seconds` es un **tope duro de presupuesto por despacho**: `codex exec` no
ofrece limite de turnos ni de tokens, asi que el arnes mata el proceso al
expirar y marca la fila `KILLED`. Un agente descarrilado no se come el
presupuesto; deja una fila que dice que se paso.

Toda fila lleva `routing_ok`. Si el par observado no coincide con el del brazo,
la fila se marca `NO` y el arnes avisa: esa ejecucion pertenece a otro brazo y no
se promedia con las demas. `NO-DISPATCH` significa que el padre hizo el trabajo
en vez de delegar, que es un fallo del despacho y no una fila medida en el par
del padre.

El modelo **y el coste** se leen del rollout del subagente, no del hilo padre de
`codex exec`. El padre corre siempre en el default del host, asi que medir su
modelo marcaria todas las filas fuera de brazo; y su consumo es solo la
orquestacion —despachar y resumir— asi que medirlo subestima el brazo en un orden
de magnitud. En el bloque A el padre reportaba ~23-43k tokens no cacheados frente
a los ~65-84k reales del subagente. La union es `parent_thread_id`.

## Registro

Una fila por ejecucion, sin transcripciones ni secretos:

```text
tarea | bloque | brazo | orden | aceptado_1er_intento | blocking_encontrados |
important_encontrados | blocking_escapados | important_escapados | correcciones |
lotes_correccion | tokens_cacheados | tokens_no_cacheados | tokens_salida |
tokens_reasoning | creditos | reloj_min | fallos_herramienta | timeouts_espera |
coste_hasta_aceptado
```

El routing efectivo de cada ejecucion se verifica con
[`tests/runtime-parity.md`](../../tests/runtime-parity.md). Una fila cuyo modelo
observado no coincida con el esperado se descarta: pertenece a otro brazo.

## Amenazas a la validez

- **n pequeno en horizonte largo.** Es el bloque mas informativo y el menos
  concluyente. No se convierte en porcentaje, y su evidencia solo mueve la
  decision en un sentido (ver la regla asimetrica arriba).
- **Blinding parcial.** El operador no puede ir ciego; solo el reviewer. Los
  bloques con intervencion del operador son los mas sospechosos.
- **Emparejamiento y aprendizaje.** Repetir la misma tarea en varios brazos
  favorece al ultimo. Lo mitiga el orden aleatorio, no lo elimina.
- **Coste variable del host.** El contexto fijo del host domino el coste medido
  en el piloto de v0.1; hay que aislarlo antes de atribuir un ahorro al routing.

## Estado

Los bloqueantes de routing que impedian lanzar estan resueltos y verificados por
despacho real: la escalada se despacha por `agent_type` (diez estados), el alias
se resuelve por host, y el fork de turnos esta prohibido porque anula el alias.

Lo que no esta resuelto es el **corpus**.

### La calibracion no son datos del piloto

Una primera pasada sobre PenthOX se ejecuto con `?? node_modules` en la baseline,
con el bloque C subespecificado y sin reviewer ciego. Sus numeros quedan como
`calibration-invalid` y no se mezclan con el experimento. Sirvieron para lo que
sirve una calibracion: encontrar los fallos del instrumento antes de gastar el
presupuesto.

La evidencia de esa calibracion identifica exactamente cinco defectos historicos
del arnes:

1. Se usaba el hilo padre en vez del hilo hijo.
2. Se media el coste de orquestacion y del hilo padre en vez del coste del hilo
   hijo.
3. La union dependia de un ID de `thread.started` que podia diferir de
   `payload.id`.
4. La baseline quedaba sucia por dependencias instaladas dentro del worktree.
5. Se truncaba la parte entera de costes de al menos `$1`.

Las correcciones auxiliares del arnes no aumentan este recuento.

### El corpus no admite briefs ciegos con suite oculta

El spec review previo bloqueo cinco de los siete briefs, y el motivo es
estructural, no de redaccion:

> Distintas implementaciones razonables podrian compilar y cumplir literalmente
> cada objetivo mientras fallan la suite oculta; continuar mediria capacidad de
> adivinar contratos, no capacidad de implementar el brief.

La suite canonica de estas tareas asserta **contenido** —que checks concretos, que
severidades, que exposiciones cuentan como sensibles, la tabla entera de estados y
transiciones— y no solo forma. Especificarlo en el brief es transcribir el diseno
del commit, y entonces ambos brazos aceptan y el bloque no discrimina; no
especificarlo mide una moneda al aire. La calibracion mostro los dos extremos:
8/8 aceptados con briefs apretados, y una decision por `void` frente a `number`
con un brief flojo.

Un control lo confirmo: con el contrato publico anadido, C1 pasa esa parte de la
revision; sin el, D1 sigue bloqueado por el mismo motivo.

### Consecuencia

`C1` era la unica tarea del corpus elegible como A/B valido, y solo despues de
declarar su contrato publico y sus puntos de entrada. Fue la unica tarea
ejecutada en la ultima fase: `balanced` y `frontier` rutearon correctamente,
pero ambos fueron no aceptados.

El brief conservado en [`briefs-v0.2/C1.txt`](briefs-v0.2/C1.txt), SHA-256
`169fc3c5bc50006f27660d1cc94817556c1ff94ec2722d5aff8af85c985f5437`, es la
revision v2 congelada despues del spec gate y antes de despachar ambos
implementers. Es el contenido que recibieron los dos brazos.

### Resultado observado de la ultima fase

La tabla de resultados conserva unicamente las dos filas candidatas de `C1`:

| Tarea | Brazo | Routing | Aceptado | Cached | Uncached | Output | Reasoning | Reloj (s) | Coste impl. | Coste review(s) | Total |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| C1 | balanced | yes | no | 2868992 | 134947 | 12611 | 7073 | 402 | 0.0995 | 2.1228 | 2.2223 |
| C1 | frontier | yes | no | 2465536 | 141855 | 16713 | 8659 | 507 | 1.8879 | 2.6619 | 4.5498 |

Hubo tres reviews ciegas: una `pass` falsa con `Blocking=0` e `Important=0`, y
dos `changes-requested`, ambas con `Blocking=1` e `Important=1`. El defecto
reproducible fue un barrido sin prueba de orfandad que libera reservas con un
despacho vivo; tambien existe en el commit de referencia `279d571`.

El overhead registrado de especificacion y orquestacion fue `$0.9770`; el total
API-equivalente historico fue `$7.7491` (aprox. `$7.75`). Estas cifras son solo
calibracion de `C1`, no un resultado de A/B.

### Intentos excluidos por spec gate

Estos intentos no se ejecutaron, no son filas candidatas y no se promedian:

| Tarea | Estado | Motivo |
| --- | --- | --- |
| A1 | `NOT_RUN_SPEC_GATE` | Corpus invalido: brief no permite derivar la suite canonica. |
| A2 | `NOT_RUN_SPEC_GATE` | Corpus invalido: brief no permite derivar la suite canonica. |
| A3 | `NOT_RUN_SPEC_GATE` | Corpus invalido: brief no permite derivar la suite canonica. |
| B1 | `NOT_RUN_SPEC_GATE` | Corpus invalido: brief no permite derivar la suite canonica. |
| B2 | `NOT_RUN_SPEC_GATE` | Corpus invalido: brief no permite derivar la suite canonica. |
| D1 | `NOT_RUN_SPEC_GATE` | Corpus invalido: brief no permite derivar la suite canonica. |

### Estado final

v0.2 queda **abortado/inconcluso por corpus inválido**. A, B y D no fueron
medidos; no existe veredicto A/B/C/D. Los resultados son solo de calibracion y
se necesita un piloto v0.3 prospectivo separado, con corpus valido.

Un piloto sobre las cuatro preguntas originales necesita tareas cuyo criterio sea
derivable del enunciado: contrato publico explicito en el issue, o suites que
verifiquen una propiedad —idempotencia, un invariante, un limite— en vez de un
catalogo de contenidos.
