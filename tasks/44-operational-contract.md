# Issue 44: coordinacion y recursos de pruebas

## Estado vigente

- Resultado: aplicar al contrato global las mejoras observadas en Penthos.
- Estado: preparado para revision del usuario; implementacion, checks y review independientes terminados.
- Responsable: lead de esta tarea; reviewer independiente read-only al congelar diff.
- Checkout: `.worktrees/44-operational-contract`, `feat/44-operational-contract`.
- Base: `e1c2e7dd23f07a2019ee56075519cce7d3d375ba`.
- Baseline: ocho suites existentes verdes antes de editar.
- Autoridad: implementar, verificar y staging; sin commit/push/merge ni instalacion global.
- Dependencia: Penthos #71 conserva AGENTS.md y su diff. Su lead cedio package.json,
  CI, launcher nuevo y tests/support nuevos para desarrollar #80 en otro worktree;
  la integracion y simplificacion de instrucciones esperan su cierre.
- Siguiente accion: revisar el diff staged; commit/push requieren aprobacion del usuario.

## Contrato y limites

Preparacion reproducible antes del baseline; autoridad de desarrollo separada
de ejecucion y publicacion; menos delegacion administrativa, reutilizacion por
paquete y recorrido integrado temprano; estado/evidencia compactos; temporales
exclusivos y limpieza por propiedad. Sin nuevos roles, formato de retorno ni
framework. La herramienta macOS y el contexto personal pertenecen a Penthos.

## Verificacion de la entrega

- Suites: contract, scaffolding, registry, gen_agents, ci_reviewer, orchestration,
  pilot_run y protect_repo, mediante `sh tests/<nombre>_test.sh`.
- Escenarios: [operational-scenarios](../tests/operational-scenarios.md).
- Comparar roles generados y seccion de retorno con la base.
- Revision independiente sobre diff congelado; el lead verifica sus resultados.
- Conservar trabajo ajeno y el registro de Penthos mediante MCP sin sobrescribir #71.

Resultados del lead: las ocho suites pasan; `git diff --cached --check` limpio.
Los diez renders Codex y diez Claude son identicos byte a byte a la base; los
roles y el envelope no cambiaron. Reviewer `operational_review`, Sol xhigh
observado: PASS, doce escenarios coherentes y reentrada suficiente desde este
registro. Su primer snapshot fue `115ab3843a82ec448be85d4805b2b777b9d91f61a91a8b67ed603ccc893039df`;
el unico cambio posterior es este cierre de estado. No es una medicion de ahorro
ni un piloto live; falta la validacion del lanzador y su uso en Penthos.
