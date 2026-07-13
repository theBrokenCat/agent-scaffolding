# Políticas operativas

Este archivo es el índice operativo único. Complementa `AGENTS.md`, `ROUTER.md`,
`agents/README.md` y `profiles/README.md`; no amplía su autoridad. Resuelve
conflictos con la precedencia de `AGENTS.md`. La regla más restrictiva se aplica
solo a Git o remoto, operaciones destructivas, producción y seguridad; aplica
STOP únicamente cuando esa precedencia no resuelva el conflicto.

## 1. Git y GitHub

### Modos y protección de ramas

- `local-only` permite trabajo local autorizado, pero no operaciones remotas.
- `autonomous-pr` permite crear ramas o worktrees, commits lógicos, push de la
  rama de feature y creación o actualización de una draft PR sin reconfirmar.
- El modo se obtiene solo del bloque YAML canónico y confiable definido en
  `AGENTS.md`. Si falta, es inválido, no estaba aprobado en el SHA base de la
  tarea o cambió durante la tarea, el fallback es `local-only`.
- `main` está protegida: nunca se hace push directo. Merge, despliegue, force
  push y borrado remoto requieren autorización explícita.

### Inspección, inicio y baseline

Antes de cualquier mutación, inspecciona el repositorio sin alterar checkouts:

```sh
git status --short
git branch --show-current
git rev-parse --abbrev-ref @{upstream} # si existe
git remote
git worktree list --porcelain
```

La inspección y los flujos operativos usan nombres de remotos, nunca su URL. Si
diagnosticar conectividad exige conocerla, no la consultes en una sesión con
output registrado: usa una herramienta del host que devuelva campos ya
sanitizados o pide al usuario una inspección segura. En particular, NO ejecutes
`git config --get remote.origin.url` en sesiones registradas. Si una herramienta
saneada devuelve el valor, represéntalo únicamente como `<redacted>`; los
formatos desconocidos nunca se imprimen.

Después, cuando el modo y los permisos permitan acceso remoto, ejecuta
`git fetch --prune`. En `local-only`, no hagas fetch salvo autorización
específica. Para una tarea nueva, crea la rama corta y su worktree directamente
desde `origin/main`, por ejemplo con
`git worktree add -b <rama> <ruta> origin/main`; no cambies ni hagas pull del
checkout actual.

Actualiza `main` solo en el worktree que la inspección identifique como dueño de
`main`, después de comprobar allí que está limpio y no contiene trabajo ajeno.
Cuando esté autorizado, usa `git -C <ruta-main> pull --ff-only`; si no se cumplen
esas condiciones, no lo actualices.

Registra el SHA base y ejecuta un baseline proporcional antes de editar. Si el
baseline está rojo, conserva la salida y separa fallos preexistentes de posibles
regresiones. Aplica STOP por defecto. Continúa solo con autorización explícita,
scope y verificaciones acotados, y una prueba final de que el cambio no empeora
el baseline.

Durante el trabajo:

- Mantén cambios pequeños y relacionados.
- Usa Conventional Commits en inglés y un commit por cambio lógico.
- No uses `git add .` en un worktree sucio; añade únicamente rutas revisadas.
- En `autonomous-pr`, haz push solo después de un checkpoint verde y abre o
  actualiza una draft PR. En `local-only`, no hagas push ni abras PR.
- Conserva cambios ajenos y detente si contradicen el alcance o la propiedad.

### Sincronización, PR y CI

Una rama personal puede hacer rebase automático sobre `origin/main` solo antes
del primer push. Después del primer push, sincroniza con merge de `origin/main`;
un rebase seguido de `--force-with-lease` requiere autorización explícita. En
una rama compartida usa merge y nunca un rebase destructivo.

La PR debe incluir resumen y problema resuelto, evidencia de verificación,
riesgos, documentación afectada, estado de CI y review. La revisión de
requisitos, la revisión del diff y el feedback de PR comparten un único
presupuesto agregado máximo de dos rondas, nunca presupuestos separados. Una
ronda es una revisión y su retorno. Las correcciones totales son las definidas
por nivel en `agents/README.md`: `fast` cero, `standard` una y `deep` una. Una
corrección no crea otro presupuesto y su re-revisión consume otra ronda. Al
agotar rondas o correcciones, aplica STOP y replantea. Para CI hay tres intentos
razonados como máximo; después documenta el diagnóstico, preserva el estado y
aplica STOP.

### Merge y cierre

Antes del cierre, repite la inspección completa de estado, rama, upstream,
remotos y worktrees usada al inicio. El merge requiere siempre autorización
explícita. Usa squash por defecto y, cuando la herramienta lo permita, fija el
expected head para evitar integrar un SHA distinto al revisado.

Tras confirmar el merge, actualiza `main` solo en su worktree identificado,
limpio y sin trabajo ajeno, mediante `git -C <ruta-main> pull --ff-only`. Elimina
la rama o el worktree solo si el merge está confirmado y no contienen trabajo
sin integrar. Cuando el modo y los permisos lo permitan, termina con
`git fetch --prune`.

Producción y deploy son operaciones separadas del merge y requieren aprobación
explícita, incluso cuando la PR ya esté integrada. Protege secretos en comandos,
logs, commits y salidas. No ejecutes operaciones destructivas, force push,
limpieza, borrados o restauraciones sin autoridad explícita y comprobaciones de
estado y recuperación.

## 2. Coste y contexto

Usa los límites `fast`, `standard` y `deep` definidos en `agents/README.md`.
Carga solo instrucciones, archivos, símbolos y evidencia necesarios; no leas el
repositorio completo por defecto. Entrega briefs acotados con punteros y
extractos mínimos, y no reindexes sin necesidad. Selecciona modelos por capacidad
y coste requerido, no por nombres de producto.

Los caps agregados por defecto son `fast` 12k, `standard` 40k y `deep` 120k,
contados como input más output consumido o facturable que reporte el host para
lead y agentes. Los caps individuales son: `fast`, lead 12k;
`standard`, lead 32k y subagente 12k; `deep`, lead 60k y cada worker 30k. El cap
agregado se aplica primero. El usuario solo puede cambiarlos explícitamente antes
de empezar la tarea y el agente nunca los amplía automáticamente.

Usa el `token_accounting` del bloque canónico; si falta o es inválido, aplica
`unavailable`. Con `enforceable`, configura caps antes de lanzar. Con `observable`,
revisa el acumulado después de cada retorno y aplica STOP al superar el cap. Con
`unavailable`, no uses subagentes ni equipos y haz una sola pasada acotada, salvo
autorización explícita previa del usuario para aceptar delegación sin medición.
Al agotar cualquier límite, cierra nuevos despachos, preserva lo existente y
aplica STOP con estado, evidencia y trabajo pendiente.

## 3. codebase-memory-mcp

Fuera de `audit`, ejecuta `index_repository` solo cuando el índice falte o esté
desactualizado. Para descubrimiento usa, según la necesidad, `search_graph`,
`trace_path`, `get_code_snippet`, `query_graph`, `get_architecture` y
`search_code`. Recurre a `grep` o búsqueda textual para literales, configuración,
documentación, archivos no indexados o cuando el grafo sea insuficiente.

En perfil `audit` no reindexes: usa el índice existente y el fallback textual.
Si reindexar resulta imprescindible, aplica STOP y solicita autorización y el
cambio de perfil concreto antes de mutar el índice. Verifica en el repositorio
todo detalle crítico de implementación. No persistas por defecto el graph
artifact en el repositorio.

## 4. Outline

Consulta Outline mediante MCP para decisiones previas, arquitectura transversal,
despliegues o cuando el usuario lo pida. El repositorio es la fuente de verdad
para implementación activa, estado, tareas, ADRs locales y runbooks específicos
o versionados. Outline conserva conocimiento transversal y enlaza la fuente
versionada del repositorio en vez de duplicarla.

Modifica Outline solo por petición explícita y cuando los permisos MCP habiliten
escritura. Nunca eludas esos permisos mediante shell, `curl`, base de datos,
archivos de entorno u otro acceso alternativo. No expongas secretos, no elimines
documentos y no dupliques sesiones completas; enlaza o resume hacia una fuente
canónica.

## 5. Seguridad

Activa el overlay `security` para autenticación, autorización o permisos,
secretos, exposición, dependencias, input no confiable o petición explícita.
Producción por sí sola activa `production`, no `security`; combina ambos overlays
cuando concurran sus triggers. Usa el skill especializado que corresponda: diff
scan, standard o deep scan, threat model, validation o fix; no sustituyas esta
selección por un security reviewer genérico.

Los skills de seguridad no amplían autoridad, escritura, intrusividad, número de
workers ni presupuesto. Si el workflow especializado exige ampliar cualquiera
de esos límites, aplica STOP y solicita la ampliación concreta antes de seguir.

Ponytail no puede simplificar ni retirar controles de seguridad. Valida los
hallazgos antes de tratarlos como vulnerabilidades y exige pruebas para cada fix,
incluida una prueba que reproduzca el fallo cuando cambie comportamiento.

## 6. Documentación bajo demanda

- Crea o actualiza `tasks/active.md` solo para trabajo multisesión o con varios
  frentes que necesiten coordinación persistente.
- Añade `tasks/lessons.md` solo tras una corrección repetida, costosa o durable.
- Crea un ADR solo para una decisión difícil de revertir con alternativas reales.
- Registra un incidente solo si hubo impacto real; crea un runbook solo para una
  operación repetible o de producción.
- Usa GitHub Issues como backlog solo si el proyecto usa GitHub y el modo es
  `autonomous-pr` o existe autorización explícita. En `local-only`, no crees
  backlog remoto ni una copia local automática.
- Actualiza la documentación en el mismo cambio cuando cambien contratos,
  endpoints o el modelo de datos.
- No generes reportes, plantillas ni documentos persistentes para trabajo trivial.

## 7. Loops y STOP

Los límites son: descubrimiento `1+1` (una pasada inicial y una ampliación
acotada), un presupuesto agregado máximo de dos rondas de revisión entre
requisitos, diff y feedback de PR, y CI `3`. Los límites totales de corrección
son `fast` cero, `standard` una y `deep` una. Una corrección no amplía esos
presupuestos y toda re-revisión consume una ronda. No repitas un loop agotado con
otra formulación sin evidencia nueva.

Aplica STOP si se agota un límite, la precedencia no resuelve un conflicto,
faltan permisos, el scope crece o la evidencia contradice el plan. Un baseline
rojo también exige STOP por defecto y solo admite la excepción acotada definida
en la sección Git. Preserva el estado y solicita la decisión mínima necesaria,
indicando qué ocurrió, qué se intentó y qué queda pendiente. Limita el cleanup a
acciones seguras y autorizadas; cierra recursos temporales sin borrar trabajo y
entrega un reporte breve.
