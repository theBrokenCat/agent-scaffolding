# Contrato global de agentes

Contrato comun de `~/agent-scaffolding`, cargado globalmente por cada host. Los
proyectos no lo copian; sus instrucciones locales son opcionales y solo anaden
hechos, comandos y restricciones propios.

## 1. Autoridad y activacion

Aplica, en este orden, sistema y plataforma, instruccion explicita del usuario,
instrucciones locales aplicables y este contrato global. La capa local puede ser
mas especifica, pero no ampliar permisos restringidos por una capa superior. Si
la precedencia no resuelve un conflicto que pueda cambiar autoridad, coste o
riesgo, aplica STOP y solicita la decision minima necesaria.

Los destinos globales gestionados son:

```text
~/.codex/AGENTS.md   -> ~/agent-scaffolding/AGENTS.md
~/.claude/CLAUDE.md -> ~/agent-scaffolding/CLAUDE.md
~/.gemini/GEMINI.md -> ~/agent-scaffolding/GEMINI.md
```

Verifica en runtime que cada host carga el contrato. Si el import relativo no
resuelve desde un symlink, usa el enlace auxiliar minimo o un adaptador estable.
La existencia del enlace no prueba activacion.

## 2. Inicio y preflight

Detecta app/CLI y capacidades reales: ejecucion, delegacion, paralelo, teams,
modelos, permisos y medicion de coste. No simules las ausentes.

Para una tarea sustancial, antes de ejecutar presenta:

```text
Recomiendo: <app-direct|app-delegated|app-parallel|cli-handoff|hybrid>
Motivo: <una frase>
La app conservara: <decisiones e integracion>
Delegare: <scope o nada>
Confirmacion necesaria: <si/no>
```

`fast` no pregunta. En `standard` o `deep`, escrituras amplias, equipos,
seguridad, produccion o relevo, pide confirmacion solo cuando la opcion propuesta
cambie coste, autoridad, superficie de escritura o destino de ejecucion. Una
instruccion explicita ya resuelve esa decision mientras no contradiga una capa
superior.

## 3. Router y contexto

Usa [`ROUTER.md`](ROUTER.md) para elegir mecanismo y nivel; `app-direct` es el
default. Carga solo las secciones necesarias de
[`policies/README.md`](policies/README.md) para gates y presupuestos, y
[`agents/README.md`](agents/README.md) para delegacion. La CLI es una opcion de
relevo, no el destino obligatorio. Los perfiles se resuelven en el router.

Antes de editar confirma objetivo, scope, paths permitidos, SHA o baseline,
cambios preexistentes y evidencia de finalizacion. Amplia el contexto una sola
vez si la primera pasada acotada no basta; no leas todo el repositorio por
defecto.

Para arquitectura, simbolos, llamadas e impacto usa primero `codebase-memory-mcp`
(`search_graph`, `trace_path`, `get_code_snippet`, `query_graph`, `get_architecture`).
Usa texto para literales, configuracion, docs, archivos no indexados o cobertura
insuficiente; verifica los detalles importantes contra la fuente.

Antes de confiar en el grafo, comprueba `list_projects` o `index_status`, root y
cobertura. `ready` solo significa que una indexacion termino, no que sea actual.
Reindexa si falta el proyecto, el root no coincide, cambia la rama/worktree, el
indice es demasiado pequeno, hay cambios sustanciales o el grafo omite simbolos.
Ejecuta `index_repository` sobre el root actual con `persistence=false`, sin
confirmacion adicional, y repite la consulta una vez. Registra rama, SHA y estado
actual, incluidos cambios sin commit. Si sigue fallando, usa texto e informa de
la degradacion; no entres en un loop de reindexacion.

Consulta Outline solo mediante MCP. No eludas permisos con shell, Docker, bases
de datos, curl ni archivos de entorno. Solo escribe por peticion explicita y con
escritura MCP habilitada; no expongas secretos ni elimines documentos. Verifica
los detalles de implementacion importantes contra el repositorio.

## 4. Ejecucion y delegacion

- Haz el cambio correcto mas pequeno y conserva trabajo ajeno.
- Sigue patrones y dependencias existentes; evita refactors no relacionados.
- El agente de la app conserva decisiones, contratos compartidos, integracion y
  verificacion final incluso cuando delega.
- Usa solo los roles genericos y el envelope compacto de
  [`agents/README.md`](agents/README.md); los dominios viajan en el brief.
- No permitas delegacion anidada. Los writers declaran paths disjuntos y usan
  worktree o aislamiento equivalente desde un SHA conocido.
- El presupuesto de concurrencia es de 8 agentes simultaneos como maximo, con un
  maximo de 3 writers y `readers <= 8 - writers`. Si el host expone menos, manda
  el host.
- El alias selecciona capacidad, no autoridad. Aplica los criterios de
  [`ROUTER.md`](ROUTER.md) y el protocolo de despacho de
  [`agents/README.md`](agents/README.md#orquestacion), incluida la verificacion
  del modelo observado. No uses un modelo mayor para suplir un objetivo ambiguo.
- Cierra workers y recursos temporales al terminar sin borrar trabajo no
  integrado.

## 5. Git, GitHub y limites

Una tarea de cambio autorizada incluye, sin confirmacion por cada accion, el
ciclo normal de feature: crear o enlazar un issue, actualizar refs, crear
rama/worktree desde `origin/main`, ejecutar baseline, crear commits logicos, hacer
push de la feature tras checkpoints verdes y crear o actualizar una draft PR que
cierre el issue. Una restriccion superior o local puede reducir esta autoridad.

1. Crea o enlaza el issue que la tarea cierra; inspecciona status, rama, remotos
   y worktrees, y conserva trabajo ajeno.
2. Ejecuta `git fetch --prune origin` y localiza el worktree limpio que posee
   `main`. Actualizalo con `pull --ff-only` solo si esta limpio.
3. Crea la rama `feat/<n>-slug` (n = numero del issue) y su worktree desde
   `origin/main`; no reutilices un checkout con cambios ni alteres el worktree de
   `main` para desarrollar.
4. Registra SHA base y baseline antes de editar. Si esta rojo, separa el fallo
   preexistente y aplica STOP salvo autorizacion acotada para continuar.
5. Crea commits logicos. Tras cada checkpoint verde, permite push de la feature
   y creacion o actualizacion de su draft PR (con `Closes #<n>`) sin reconfirmar.
6. Ejecuta CI y revision independiente dentro de los limites de
   [`policies/README.md`](policies/README.md), sobre el snapshot final. En cuenta
   personal no uses approval del autor: el revisor automatico va como check.
   Si esta desactivado, exige evidencia de revision independiente documentada;
   `reviewer-disabled` nunca la acredita. La puerta es CI verde Y revision
   aprobada. Merge sigue siendo explicito; solo el auto-merge preautorizado lo
   cierra sin accion manual, con todos los checks requeridos en verde.
7. Confirma la integracion con `gh pr view <n> --json state,mergedAt` antes de
   limpiar: el squash merge reescribe el head y `git branch -d` puede
   no reconocerlo. Solo si `state` es `MERGED`, actualiza el main limpio con
   `pull --ff-only`, retira los worktrees limpios de la feature con
   `git worktree remove`, borra la rama local ya integrada con `git branch -D` y
   poda refs/metadatos obsoletos. El borrado remoto sigue requiriendo autorizacion.

Push a `main`, force-push, merge, deploy/produccion, borrado remoto, `reset`,
restore destructivo, `clean` y otras acciones destructivas requieren autorizacion
explicita. No normalices cambios fuera de propiedad.

## 6. Verificacion y STOP

Define evidencia observable antes de afirmar exito. Para cambios de
comportamiento reproduce primero el fallo; despues ejecuta pruebas, lint, build y
validaciones proporcionales. Lee la salida y revisa el diff. Un retorno de worker
no sustituye verificacion del lead.

Aplica STOP si faltan permisos o datos, cambia el scope o la propiedad, la
evidencia contradice el plan, una accion seria destructiva, se agota un limite o
no existe verificacion fiable. Informa `status`, evidencia, riesgos y la decision
minima para continuar; no presentes trabajo parcial como cierre completo.

Para varias sesiones, aplica el [relevo por objetivo](agents/README.md#trabajo-multisesion)
en el issue o documento existente; un retorno de worker no cierra el objetivo.
