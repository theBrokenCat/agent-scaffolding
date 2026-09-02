# Piloto v0.2: routing de modelos y orquestacion

Diseno del piloto que debe validar —o refutar— el routing de la fase 2. Se
registra **antes** de ejecutarlo: los criterios de abajo estan pre-registrados y
no se reinterpretan despues de ver los numeros.

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
| Horizonte largo | 1 | donde mas te juegas: el gate de "cuanto dura" |

El bloque de horizonte largo tiene n = 1 y **no** produce una media: produce una
observacion cualitativa. Se registra como tal. La evidencia externa que motiva el
gate —modelos sub-frontier que en runs de 100+ tareas caen a 40,7 % de aciertos
frente a 63,7 %, quemando 2,65x tokens— predice que ahi es donde un brazo barato
se rompe; una sola observacion puede ser consistente con eso, no probarlo.

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

- **n = 1 en horizonte largo.** Es el bloque mas informativo y el menos
  concluyente. No se convierte en porcentaje.
- **Blinding parcial.** El operador no puede ir ciego; solo el reviewer. Los
  bloques con intervencion del operador son los mas sospechosos.
- **Emparejamiento y aprendizaje.** Repetir la misma tarea en varios brazos
  favorece al ultimo. Lo mitiga el orden aleatorio, no lo elimina.
- **Coste variable del host.** El contexto fijo del host domino el coste medido
  en el piloto de v0.1; hay que aislarlo antes de atribuir un ahorro al routing.

## Estado

Diseno registrado. Ejecucion pendiente: no hay todavia ninguna medicion, y
ninguna cifra de la tabla de objetivos esta demostrada.
