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

1. **Issue y refs.** Crea o enlaza el issue que la tarea cierra. Ejecuta
   `git status --short`, identifica rama, remotos y worktrees, y despues
   `git fetch --prune origin`. No muestres URLs ni secretos.
2. **Main limpio.** Localiza con `git worktree list --porcelain` el worktree que
   posee `main`. Si esta limpio, actualizalo con `git -C <main> pull --ff-only`.
   Si esta sucio, no lo alteres ni escondas sus cambios.
3. **Aislamiento.** Crea una rama `feat/<n>-slug` (n = numero del issue) y su
   worktree desde `origin/main`, por ejemplo
   `git worktree add -b feat/<n>-slug <path> origin/main`. Cada writer parte
   del SHA registrado y posee paths disjuntos. Contratos compartidos, schemas,
   lockfiles, migrations, generated, snapshots e integracion pertenecen al lead
   salvo asignacion unica y explicita.
4. **Baseline.** Registra SHA base y ejecuta verificaciones proporcionales antes
   de editar. Si el baseline esta rojo, separa el fallo preexistente y aplica
   STOP salvo autorizacion acotada para continuar.
5. **Checkpoints.** Revisa el diff, crea commits logicos y ejecuta las
   verificaciones aplicables. Tras un checkpoint verde, haz push de la feature
   con upstream si hace falta y crea o actualiza una draft PR con `Closes #<n>`.
   No reconfirmes cada commit, push o actualizacion de draft PR.
6. **CI y revisor.** La draft PR incluye alcance, cambios, verificaciones y
   riesgos. CI permite tres intentos razonados y requisitos/diff/feedback
   comparten dos rondas de review. En cuenta personal el revisor no puede aprobar
   su propia PR: se ejecuta como check de CI, no como approval. La puerta antes de
   integrar es CI verde Y revisor verde. Al agotar un limite, aplica STOP.
7. **Merge.** El merge es un gate explicito. El auto-merge solo procede cuando
   esta preautorizado y con todos los checks requeridos (CI y, cuando este activo,
   revisor) en verde; hasta que el revisor-en-CI se active, gobierna la capa
   determinista. Merge y deploy/produccion son gates separados.
8. **Post-merge.** Confirma la integracion con `gh pr view <n> --json state,mergedAt`
   antes de limpiar; el squash merge por defecto reescribe el head, asi que
   `git branch -d` siempre falla y dejaria ramas y worktrees huerfanos. Solo si
   `state` es `MERGED`: actualiza el worktree limpio de `main` con
   `git -C <main> pull --ff-only`, retira los worktrees limpios de la feature con
   `git worktree remove`, borra la rama local integrada con `git branch -D`,
   ejecuta `git worktree prune` y actualiza refs con `git fetch --prune origin`.
   El borrado remoto sigue requiriendo autorizacion.

### Auto-merge en cuenta personal

Sin org rulesets, el candado se aplica por repo con `scripts/protect-repo`: crea o
actualiza el ruleset de la rama por defecto (PR obligatoria, checks requeridos,
bloqueo de force-push y borrado, conversaciones resueltas) y activa el auto-merge
de repositorio con squash. El revisor va como check de CI porque el autor no puede
aprobar su propia PR. El auto-merge cierra la PR sin accion manual solo cuando los
checks requeridos estan en verde; el check `reviewer` se exige (`--with-reviewer`)
unicamente cuando existen su secret y su harness, y hasta entonces gobierna la capa
determinista. La primera publicacion de `main`, el ruleset y `--all` sobre todos
los repos requieren autorizacion humana explicita.

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
especializado correspondiente con `domain: security` en el brief, redacta
secretos y valida hallazgos antes de afirmarlos. No existe un rol `security`:
este gate mas la skill cubren la especialidad, y un `quality-reviewer` que
encuentre algo relevante abre el gate en lugar de decidirlo. Las acciones
intrusivas requieren aprobacion.

Para produccion exige estado observado, alcance, autorizacion para actuar,
rollback verificable y comprobacion posterior. Produccion no activa seguridad si
no existe un trigger real. Ningun gate concede escritura.

## Equipos, orquestacion y loops

- Presupuesto de concurrencia: **8 agentes simultaneos como maximo**, de los
  cuales **como maximo 3 writers**; `readers <= 8 - writers`. El techo real es el
  del host; si expone menos, manda el host.
- `fast` no delega. `standard` permite un solo worker activo; implementacion y
  revision independiente pueden sucederse. `deep` puede usar
  el presupuesto completo, y solo mientras cada agente adicional tenga un scope
  real e independiente.
- No hay delegacion anidada ni writers sin propiedad y aislamiento explicitos.
- Los roles se seleccionan por necesidad conforme a `agents/README.md`.
  Exploracion y spec review requieren una pregunta o riesgo concreto; no son
  pasos obligatorios. Se mantiene la revision independiente antes de integrar.
- Prohibido spawnear con `fork_turns: "all"` cuando el alias importe, que es casi
  siempre. El fork hereda modelo y effort del padre y anula el alias en silencio.
  Red flag: *subagente despachado con fork y routing por alias*. Evidencia: un
  agente personal que declaraba Luna, despachado con fork, corrio en Sol y nunca
  habia corrido en Luna.
- Prohibido escalar por override. Con `agent_type`, la definicion del archivo gana
  a `model` y `reasoning_effort` de `spawn_agent`: el override se acepta y se
  ignora. La escalada se despacha por nombre, con la variante materializada del
  rol. Red flag: *escalada intentada por override en vez de por agent_type*.
- Verificacion de routing: si el modelo observado no coincide con el alias, es
  FALLO. No lo aceptes como variante ni promedies su coste con el del alias.
- Spawnea todo el lote independiente antes de la primera espera. Espera con
  bounds largos, procesa eventos, retira agentes terminales y vuelve a esperar;
  `wait_agent` despierta por evento o timeout y no es un wait-for-all atomico.
  Un despertar sin cambio de estado no autoriza razonamiento nuevo ni una ronda
  de esperas mas cortas.
- Los hallazgos se agrupan contra un snapshot congelado y se corrigen en **un
  lote** al owner de esos paths. Ningun agente nuevo por microhallazgo, y ningun
  gate amplio re-ejecutado despues de cada microfix.
- Correcciones en paralelo solo si son causalmente independientes y con paths
  disjuntos. Si un hallazgo `Blocking` invalida el snapshot, congela el lote
  despues de cerrar el inventario causal.
- Reset del contrato a la segunda reapertura del mismo seam o familia de
  invariantes; no una tercera ronda de parches.
- SLA de reviewer: al agotarse su bound, sustituye al reviewer o declaralo
  bloqueado con evidencia; no esperes indefinidamente ni des por aprobado lo que
  nadie reviso. Conserva siempre una revision final integrada.
- Descubrimiento: una pasada inicial y una ampliacion acotada con evidencia nueva.
- Cada worker: una pasada y como maximo una correccion solicitada por el lead.
- Requisitos, diff y feedback de PR comparten como maximo dos rondas de review.
- CI permite tres intentos razonados; no repitas el mismo intento sin evidencia.

Al agotar un limite, detiene nuevos despachos, preserva estado y aplica STOP. No
cambies de rol, modelo, alias o formulacion para reiniciar un loop agotado; subir
de curva no es una via para repetir un intento ya agotado.

El protocolo completo, con roles, aliases y excepciones, esta en
[`agents/README.md`](../agents/README.md).

## Verificacion y cierre

Define antes de ejecutar que evidencia demuestra cada criterio. Para conducta,
reproduce el fallo antes del fix. Ejecuta checks proporcionales, lee sus salidas,
revisa `git diff --check` y el diff completo. El lead verifica de nuevo despues
de integrar retornos.

Si una comprobacion falta, declara el motivo y riesgo residual. Cierra con el
envelope de [`agents/README.md`](../agents/README.md) cuando exista relevo; no
presentes `partial` o `blocked` como exito.
