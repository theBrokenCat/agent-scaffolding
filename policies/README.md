# Politicas operativas

Complementan [AGENTS.md](../AGENTS.md) sin conceder permisos. Este archivo
conserva gates y presupuestos; el contrato global contiene autoridad, preflight,
Git, contexto y verificacion.

## Confirmacion y mutacion

Aplica [autoridad y preflight](../AGENTS.md#2-inicio-y-preflight).
Una herramienta disponible no implica permiso. `read-only` excluye escrituras
locales y remotas; escribir requiere scope, ownership, baseline y verificacion.

## Git, worktrees y PR

El ciclo autorizado y el cleanup estan en [AGENTS.md](../AGENTS.md#5-git-github-y-limites).
No hay una segunda politica de Git aqui. Las restricciones propias de GitHub,
bootstrap, rulesets, auto-merge y checks estan en [.github/README.md](../.github/README.md).
No cambies configuracion remota ni publiques fuera de la autoridad ya concedida.

## Contexto, grafo y Outline

### Frescura de codebase-memory-mcp

Aplica la comprobacion de root, cobertura, SHA y dirty state de
[AGENTS.md](../AGENTS.md#3-router-y-contexto), incluida una sola reindexacion con
`persistence=false` y fallback textual cuando el indice siga sin ser fiable.
Usa `fast` para refrescos cotidianos, `moderate` para relaciones cross-file y
`full` para arquitectura o recuperar cobertura. `persistence=true` escribe un
artefacto en el repo y requiere peticion explicita.

Outline se consulta solo por MCP conforme al contrato global; no dupliques
sesiones completas ni uses otra via para eludir permisos. El repositorio es la
fuente de implementacion, no una nota historica.

## Seguridad y produccion

Activa seguridad para autenticacion, autorizacion, permisos, secretos, exposicion,
dependencias, input no confiable o peticion explicita. Usa el skill especializado
con `domain: security`, redacta secretos y valida hallazgos antes de afirmarlos.
No existe un rol adicional: el reviewer abre el gate y no lo sustituye.
Las acciones intrusivas requieren autorizacion explicita.

Produccion exige estado observado, alcance, autorizacion para actuar, rollback
verificable y comprobacion posterior. No activa seguridad sin un trigger real y
ningun gate concede escritura. Merge y deploy son decisiones separadas.

## Equipos, orquestacion y loops

Roles, limites de concurrencia, propiedad, despacho, espera y correcciones viven
en [agents/README.md](../agents/README.md#orquestacion). Son obligatorios cuando
se delega; un enlace no convierte estas reglas en opcionales.

Presupuestos de ejecucion:

- Descubrimiento: una pasada inicial y una ampliacion con evidencia nueva.
- Cada worker: una pasada y como maximo una correccion solicitada por el lead.
- Requisitos, diff y feedback de PR: como maximo dos rondas de review.
- CI: tres intentos razonados; no repitas el mismo intento sin evidencia nueva.

Al agotar un limite, detiene nuevos despachos, preserva estado y aplica STOP. No
cambies rol, modelo, alias o formulacion para reiniciar un loop agotado: escalar
no es una via para eludir el limite. Los
budgets del brief pueden ser menores; ampliar un limite necesita nueva autoridad.

## Verificacion y cierre

Aplica [verificacion y STOP](../AGENTS.md#6-verificacion-y-stop). Declara checks
omitidos y riesgo residual; el lead verifica despues de integrar. El
[retorno comun](../agents/README.md#envelope-de-retorno) distingue terminar una
revision de aprobarla. CI desactivada, review parcial y falta de evidencia nunca
satisfacen un gate de revision independiente.
