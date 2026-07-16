# Politicas operativas

Estas politicas complementan [`AGENTS.md`](../AGENTS.md). No conceden permisos;
las instrucciones locales son opcionales y una regla inferior nunca amplia la
autoridad de una capa superior.

## Confirmacion y mutacion

- `fast` ejecuta sin pregunta adicional dentro del scope autorizado.
- En `standard` o `deep`, confirma solo si la recomendacion cambia coste,
  autoridad, destino de ejecucion, equipo o superficie de escritura.
- Una vez autorizada una tarea de cambio, su ciclo normal de feature no requiere
  confirmaciones repetidas para rama/worktree, commits, checkpoint pushes o
  draft PR.
- Acciones intrusivas, produccion, merge, deploy, force-push y operaciones
  destructivas requieren la autoridad explicita aplicable.
- Una herramienta disponible no implica permiso para usarla.

## Git, worktrees y PR

Una tarea de cambio autorizada concede el siguiente ciclo de feature sin pedir
permiso para cada paso. Las restricciones superiores o locales siguen mandando.

1. **Inspeccion y refs.** Ejecuta `git status --short`, identifica rama, remotos y
   worktrees, y despues `git fetch --prune origin`. No muestres URLs ni secretos.
2. **Main limpio.** Localiza con `git worktree list --porcelain` el worktree que
   posee `main`. Si esta limpio, actualizalo con `git -C <main> pull --ff-only`.
   Si esta sucio, no lo alteres ni escondas sus cambios.
3. **Aislamiento.** Crea una rama corta y worktree desde `origin/main`, por
   ejemplo `git worktree add -b <feature> <path> origin/main`. Cada writer parte
   del SHA registrado y posee paths disjuntos. Contratos compartidos, schemas,
   lockfiles, migrations, generated, snapshots e integracion pertenecen al lead
   salvo asignacion unica y explicita.
4. **Baseline.** Registra SHA base y ejecuta verificaciones proporcionales antes
   de editar. Si el baseline esta rojo, separa el fallo preexistente y aplica
   STOP salvo autorizacion acotada para continuar.
5. **Checkpoints.** Revisa el diff, crea commits logicos y ejecuta las
   verificaciones aplicables. Tras un checkpoint verde, haz push de la feature
   con upstream si hace falta y crea o actualiza una draft PR. No reconfirmes
   cada commit, push o actualizacion de draft PR.
6. **CI y review.** La draft PR incluye alcance, cambios, verificaciones y
   riesgos. CI permite tres intentos razonados y requisitos/diff/feedback
   comparten dos rondas de review. Al agotar un limite, aplica STOP; no hagas
   merge automatico.
7. **Merge.** Solicita autorizacion explicita para integrar el head revisado.
   Merge y deploy/produccion son gates separados.
8. **Post-merge.** Confirma el merge y que no queda trabajo sin preservar.
   Actualiza el worktree limpio de `main` con `git -C <main> pull --ff-only`.
   Retira solo worktrees limpios, elimina solo ramas locales integradas mediante
   `git branch -d`, ejecuta `git worktree prune` y actualiza refs con
   `git fetch --prune origin`. El borrado remoto sigue requiriendo autorizacion.

Push directo a `main`, force-push, merge, deploy/produccion, borrado remoto,
`reset`, restore destructivo, `clean` y cualquier operacion destructiva requieren
confirmacion explicita. Nunca uses cleanup para resolver cambios ajenos.

## Contexto, grafo y Outline

Para descubrir codigo usa primero `codebase-memory-mcp`: `search_graph`,
`trace_path`, `get_code_snippet`, `query_graph` y `get_architecture`. Usa busqueda
textual para literales, configuracion, documentacion, archivos no indexados o
cuando el grafo no baste. Verifica detalles importantes contra el repositorio.

### Frescura de codebase-memory-mcp

Antes de usar el grafo como evidencia para arquitectura, impacto o navegacion:

1. Consulta `list_projects` o `index_status` y confirma el root del repositorio.
2. Contrasta su escala con los archivos de codigo y prueba una consulta
   representativa cuando la cobertura sea dudosa. El estado `ready` no prueba
   que el indice este completo o actualizado.
3. Considera el indice stale o incompleto si falta, apunta a otra ruta, tiene
   una escala inverosimil, cambio la rama/worktree, hubo cambios sustanciales o
   el texto contiene un simbolo conocido que el grafo no encuentra.
4. Reindexa el root actual con `persistence=false` y repite la consulta una sola
   vez. Esta actualizacion del estado MCP queda autorizada dentro de una tarea de
   descubrimiento y no requiere confirmacion adicional porque no escribe en el
   repositorio.
5. Si sigue fallando, degrada a busqueda textual, informa que el grafo no es
   fiable para esa tarea y no vuelvas a reindexar en el mismo loop.

Usa `fast` para refrescos cotidianos, `moderate` cuando importen relaciones
cross-file y `full` para recuperacion de un indice incompleto, arquitectura o
analisis profundo. `persistence=true` puede crear un artefacto compartible en el
repositorio y requiere peticion explicita. La indexacion siempre refleja el
filesystem del worktree elegido, incluidos cambios sin commit; registra rama,
SHA y estado dirty cuando esa diferencia pueda afectar las conclusiones.

Usa Outline por MCP para documentacion, decisiones previas y despliegues. No
eludas permisos mediante shell, Docker, Postgres, MinIO, `curl` ni `.env`. Solo
escribe por peticion explicita con escritura MCP habilitada. No expongas secretos,
no elimines documentos y no dupliques sesiones completas. El repositorio sigue
siendo fuente de verdad para implementacion activa.

## Seguridad y produccion

Activa gate de seguridad para autenticacion, autorizacion, permisos, secretos,
exposicion, dependencias, input no confiable o peticion explicita. Usa el skill
especializado correspondiente, redacta secretos y valida hallazgos antes de
afirmarlos. Las acciones intrusivas requieren aprobacion.

Para produccion exige estado observado, alcance, autorizacion para actuar,
rollback verificable y comprobacion posterior. Produccion no activa seguridad si
no existe un trigger real. Ningun gate concede escritura.

## Equipos y loops

- Equipo maximo: lead y tres workers; `standard` permite solo uno.
- No hay delegacion anidada ni writers sin propiedad y aislamiento explicitos.
- Descubrimiento: una pasada inicial y una ampliacion acotada con evidencia nueva.
- Cada worker: una pasada y como maximo una correccion solicitada por el lead.
- Requisitos, diff y feedback de PR comparten como maximo dos rondas de review.
- CI permite tres intentos razonados; no repitas el mismo intento sin evidencia.

Al agotar un limite, detiene nuevos despachos, preserva estado y aplica STOP. No
cambies de rol, modelo o formulacion para reiniciar un loop agotado.

## Verificacion y cierre

Define antes de ejecutar que evidencia demuestra cada criterio. Para conducta,
reproduce el fallo antes del fix. Ejecuta checks proporcionales, lee sus salidas,
revisa `git diff --check` y el diff completo. El lead verifica de nuevo despues
de integrar retornos.

Si una comprobacion falta, declara el motivo y riesgo residual. Cierra con el
envelope de [`agents/README.md`](../agents/README.md) cuando exista relevo; no
presentes `partial` o `blocked` como exito.
