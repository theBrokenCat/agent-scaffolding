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
bootstrap, rulesets, auto-merge y checks estan en [.github/WORKFLOW.md](../.github/WORKFLOW.md).
No cambies configuracion remota ni publiques fuera de la autoridad ya concedida.

## Contexto, grafo y Outline

### Frescura de codebase-memory-mcp

Aplica la comprobacion de root, cobertura, SHA y dirty state de
[AGENTS.md](../AGENTS.md#3-router-y-contexto), incluida una sola reindexacion con
`persistence=false` y fallback textual cuando el indice siga sin ser fiable.
Usa `fast` para refrescos cotidianos, `moderate` para relaciones cross-file y
`full` para arquitectura o recuperar cobertura. `persistence=true` escribe un
artefacto en el repo y requiere peticion explicita.

### Mantenimiento de Outline

El lead mantiene el contexto del proyecto en su documento existente de Outline;
los workers aportan hallazgos y evidencia, no publican por su cuenta. Al empezar
o retomar, localiza y lee ese documento mediante MCP y contrasta sus datos con el
repositorio. No uses un documento solo por similitud de nombre: verifica el
proyecto y su destino. Si hay varios destinos plausibles, pide la aclaracion
minima; no crees otro documento ni un segundo backlog automaticamente.

Actualiza cuando haya un avance importante, bloqueo, decision confirmada, cambio
de siguientes pasos o de instrucciones para arrancar/probar. Al pausar o cerrar,
comprueba que el estado sigue vigente y corrige solo diferencias relevantes.
No edites por calendario, por cada herramienta ni si no hay informacion nueva.

Conserva una vista breve y util para el usuario:

- Objetivo y estado: que se hace, que esta pendiente o bloqueado y por que.
- Ubicacion: proyecto y checkout/rama de trabajo cuando ayuden a retomarlo.
- Siguientes pasos: accion concreta, responsable o decision pendiente.
- Verificacion: pruebas realizadas y resultado, pruebas pendientes y comandos
  para ejecutarlas desde el directorio correcto. Distingue comprobado de previsto.
- Arranque: comandos y requisitos no secretos para lanzar el proyecto cuando
  cambien; enlaza la documentacion del repositorio si ya los explica.

Enlaza issues, PR y evidencia en vez de copiar historiales. Si Outline ya es el
registro del objetivo, actualiza ese mismo registro. Si el seguimiento detallado
vive en un issue, conserva alli ese detalle y actualiza en Outline solo el resumen
util y el enlace. No confundas implementado, staged, integrado y desplegado.

Antes de escribir, relee la version actual y modifica solo las secciones afectadas;
conserva ediciones manuales y contenido ajeno. Si la herramienta reemplaza todo el
texto, parte de esa lectura fresca y verifica que el resto se conserva. Despues,
vuelve a leer y comprueba el resultado. Publica solo hechos sustentados; marca
incertidumbres y decisiones pendientes. No incluyas secretos ni logs completos.

Si falta MCP, permiso de escritura o un destino inequívoco, informa que Outline
queda pendiente y conserva el resumen propuesto en el relevo existente. No eludas
el bloqueo ni afirmes que esta actualizado; continua el trabajo independiente
que siga autorizado. Crear, mover o reorganizar documentos requiere una peticion
especifica. La actualizacion rutinaria del documento identificado sigue la
autoridad del contrato global.

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
