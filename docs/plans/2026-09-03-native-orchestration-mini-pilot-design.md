# Diseño: smoke nativo y mini piloto prospectivo

## Objetivo

Validar dos afirmaciones distintas del scaffolding sin depender del corpus
histórico de PenthOX ni del arnés incompleto de #28:

1. Codex lanza un lote independiente con solapamiento real y espera por eventos
   sin polling corto.
2. Los tiers Luna y Sol resuelven tareas prospectivas bien especificadas sin
   pérdida oculta de aceptación.

El smoke de orquestación es gate del mini piloto.

## Smoke de orquestación

Cuatro `explorer-economy` reciben preguntas read-only independientes sobre un
snapshot congelado. Todos se spawnean antes del primer wait. El lead mantiene un
pending-set y espera con bounds de 60 s, retirando un agente por evento terminal.

Pasa si:

- los cuatro empiezan dentro de una ventana de 2 s;
- hay solapamiento efectivo;
- routing 4/4 en Luna/high;
- cero timeouts;
- cero delegación anidada;
- todos devuelven el envelope requerido.

## Corpus prospectivo mínimo

El corpus es una fixture ESM sin dependencias externas. Los implementers trabajan
en copias aisladas que contienen únicamente starter code y un brief público; los
tests oracle permanecen fuera de su cwd.

| Bloque | Tarea | Estado Luna | Contrafactual |
|---|---|---|---|
| A mecánica | Normalizar un nombre de header ASCII con errores explícitos | `implementer-economy` | `implementer-frontier` |
| B normal | Evaluar una política de retry multiarchivo con delay acotado | `implementer-balanced` | `implementer-frontier` |
| C crítica | Ledger durable de reservas con recovery e idempotencia | `implementer-frontier` | `implementer-balanced` |

Cada spec declara entradas, salidas, errores e invariantes. Un spec-reviewer
comprueba que los tests son derivables del brief antes de ejecutar implementers.
Los tests se congelan y demuestran RED sobre el starter.

## Ejecución y aceptación

- Mismo brief hash y starter SHA por pareja.
- `fork_context=false`, sin model/effort overrides.
- Parejas secuenciales en orden aleatorio reproducible (`seed=20260903`).
- Modelo/effort y tokens leídos del rollout hijo.
- Reviewer `quality-reviewer-frontier`, read-only y ciego al brazo.
- Aceptación: tests oracle verdes, routing correcto y 0 Blocking/0 Important.
- Intentos inválidos, timeout o routing mismatch no se promedian.

El mini piloto informa, no estima población: n=1 por bloque no demuestra una
tasa general. Su propósito es detectar si el mecanismo end-to-end funciona antes
de financiar un corpus mayor.

## Presupuesto

- A: 600 s por implementer.
- B: 900 s por implementer.
- C: 1.200 s por implementer.
- Review: 600 s por candidato.
- Techo del mini piloto: $10 API-equivalentes de hijos.
- No se lanza media pareja.

## Entregables

- Fixtures, briefs y tests oracle versionados en la rama de #29.
- Artefactos raw locales fuera del repo.
- Informe con timeline, routing, tests, review, tokens, coste y reloj.
- Tablas separadas MEDIDO / STRETCH.

