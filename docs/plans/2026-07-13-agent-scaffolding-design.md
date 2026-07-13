# Agent Scaffolding global - Diseno aprobado

## Objetivo

Mantener en `~/agent-scaffolding` un contrato personal unico para Codex, Claude
y Gemini. Debe estar disponible al iniciar cualquiera de esas herramientas en
cualquier directorio, exista o no configuracion local, sin copiar el scaffolding
dentro de cada proyecto.

La aplicacion es el ejecutor por defecto. Para trabajo no trivial actua tambien
como orquestador y protege su contexto: recomienda el mecanismo de ejecucion,
pide una sola confirmacion cuando la decision cambia coste, riesgo o autoridad,
y recibe de los workers retornos compactos en vez de historiales completos.

## Decisiones

### Repositorio central y activacion global

- `~/agent-scaffolding` es la fuente versionada y actualizable con Git.
- `~/.codex/AGENTS.md`, `~/.claude/CLAUDE.md` y `~/.gemini/GEMINI.md` activan
  el contrato mediante enlaces simbolicos gestionados por un instalador.
- Los adaptadores de Claude y Gemini cargan el contrato comun y solo anaden
  capacidades propias del host.
- Las instrucciones locales de un proyecto son opcionales. Anaden contexto y
  restricciones del proyecto; nunca tienen que mencionar el scaffolding.
- El instalador no sustituye contenido global sin inventario, backup y
  confirmacion. La primera migracion incorpora al contrato central las reglas
  globales validas que ya existan.

### Router app-first

Por cada tarea el lead clasifica mutacion, riesgo, coste de contexto,
independencia y capacidades disponibles. El orden recomendado es:

1. `app-direct`: la app investiga, implementa y verifica.
2. `app-delegated`: la app conserva decisiones e integracion y envia una tarea
   acotada a un worker.
3. `app-parallel`: varios workers independientes, con propiedad de escritura
   disjunta y worktrees si escriben.
4. `cli-handoff`: relevo estructurado a un agente de terminal cuando ofrece
   menor coste, aislamiento o una capacidad no disponible en la app.
5. `hybrid`: investigacion o implementacion delegada y cierre en la app.

`app-direct` es el default, no una obligacion. La aplicacion no se limita a
redactar prompts: puede ejecutar trabajo completo y lanzar agentes cuando el
host lo permita.

### Preflight y proteccion del contexto

Una tarea trivial o `fast` se ejecuta directamente sin pregunta adicional. Una
tarea `standard/deep`, de escritura amplia, varios dominios, seguridad,
produccion o relevo entre hosts recibe antes una recomendacion breve:

```text
Recomiendo: <mecanismo>.
Motivo: <coste, aislamiento, paralelismo o capacidad>.
La app conservara: <decisiones e integracion>.
Delegare: <scope acotado>.
Confirmacion necesaria: <si/no y por que>.
```

Se pide confirmacion solo si la eleccion afecta de forma material al coste,
autoridad, escrituras, numero de agentes o entorno. Si el usuario ya eligio el
mecanismo, se sigue sin repetir la pregunta salvo riesgo nuevo. La recomendacion
puede contradecir una opcion costosa, pero la eleccion final es del usuario.

El lead mantiene solo objetivo, decisiones, punteros a archivos, estado Git,
verificaciones y pendientes. Cada worker recibe el minimo contexto y devuelve:
estado, hallazgos o cambios, verificaciones, riesgos y referencias. No retorna
logs completos ni vuelve a narrar el repositorio salvo solicitud expresa.

### Modelos, roles y equipos

Los contratos usan niveles estables de capacidad:

- `economy`: tareas mecanicas y bien especificadas; inicialmente Luna.
- `balanced`: implementacion y analisis ordinario; inicialmente Terra.
- `frontier`: ambiguedad, arquitectura, integracion o riesgo alto; inicialmente Sol.

La relacion nombre-modelo vive en configuracion local y puede cambiar sin
editar los contratos. Si un host no permite elegir modelo, registra la
degradacion y elige otro mecanismo.

Los roles persistentes son `explorer`, `implementer`, `spec-reviewer` y
`quality-reviewer`. Frontend, backend, datos, debugging y UX son briefs de
dominio opcionales, no equipos permanentes. Seguridad se cubre con skills
especializados. No hay delegacion anidada. El lead integra y verifica siempre.

Los equipos solo se lanzan cuando existen al menos dos trabajos independientes
y el ahorro supera la coordinacion. Los writers usan ramas/worktrees y rutas
disjuntas; investigadores read-only pueden compartir checkout. El contrato de
lanzamiento fija objetivo, scope, base SHA, autoridad, archivos, dependencias,
modelo, presupuesto, verificacion, formato de retorno y criterio de parada.

### Git y GitHub

El flujo usa GitHub Flow: actualizar referencias, partir de `origin/main`,
crear rama corta y worktree cuando aporte aislamiento, verificar baseline,
hacer commits logicos, push de checkpoints verdes y mantener una draft PR.
El agente puede crear ramas, worktrees, commits, pushes de ramas, PRs y atender
CI. Nunca hace push directo a `main`, force-push implicito, merge, despliegue ni
operacion destructiva sin la autoridad correspondiente. El merge requiere
confirmacion explicita.

Tras el merge se actualiza `main` con fast-forward y se retiran rama/worktree
solo tras comprobar que no contienen trabajo. Los loops de discovery, review y
CI son acotados y terminan en STOP con evidencia cuando se agotan.

### Skills, MCP, Outline y settings

- Las skills se registran por nombre, origen, host, trigger, coste y estado de
  validacion. Las externas, como Ponytail y Codex Security, siguen gestionadas
  por su plugin y no se duplican.
- Ponytail se activa para implementacion minima o auditoria de sobreingenieria,
  no como modo permanente ni para retirar controles.
- `improve` produce analisis y planes para otros agentes; no implementa.
- `codebase-memory-mcp` es graph-first para descubrir codigo; texto sigue siendo
  valido para literales, configuracion, documentacion o cobertura insuficiente.
- Outline guarda conocimiento transversal o historico. El repositorio conserva
  estado operativo, decisiones locales y documentacion versionada. Solo se
  escribe en Outline por peticion explicita.
- No se versionan settings completos, secretos, trust state ni rutas privadas.
  Se versionan schemas, defaults seguros y overlays allowlisted. El instalador
  fusiona solo claves conocidas y conserva el resto.

### Instalador y recuperacion

Un unico comando `scripts/scaffolding` ofrece `install`, `status`, `doctor` y
`uninstall`. Es dry-run por defecto; `--apply` muta de forma idempotente y
atomica. Antes de cambiar un destino crea manifiesto y backup, nunca pisa un
path desconocido y permite rollback exacto.

Las instrucciones globales se enlazan como archivos. Skills y agentes se
enlazan individualmente para no ocultar contenido gestionado por plugins. Los
settings completos nunca se enlazan. Credenciales y mapping real de modelos
permanecen locales.

## Estructura objetivo

```text
agent-scaffolding/
|-- AGENTS.md
|-- CLAUDE.md
|-- GEMINI.md
|-- ROUTER.md
|-- agents/
|   |-- README.md
|   `-- roles/
|-- profiles/README.md
|-- policies/README.md
|-- skills/README.md
|-- settings/README.md
|-- settings/schemas/
|-- scripts/scaffolding
|-- scripts/lib/
|-- tests/
|-- templates/README.md
|-- docs/plans/
`-- tasks/
```

No se instala esta estructura en proyectos. `templates/` describe contratos
opcionales para iniciar proyectos nuevos, no una copia obligatoria del sistema.

## Validacion y rollout

La validacion cubre dry-run, instalacion limpia, migracion de archivos globales
existentes, idempotencia, conflicto, rollback y deteccion de enlaces rotos.
Despues se inicia Codex, Claude y Gemini desde un directorio vacio, un repo con
instrucciones locales y un subdirectorio. Se comprueba precedencia, preflight,
routing, skills y degradacion por capacidad.

El piloto se hace en `personal-life` desde una rama/worktree, sin exigir cambios
locales de scaffolding. `v0.1.0` solo se propone tras piloto satisfactorio,
revision de la draft PR y autorizacion explicita de merge y tag.

## Criterios de exito

- Cualquier host conoce el flujo al arrancar en cualquier directorio.
- Ningun proyecto necesita enlazar ni mencionar `agent-scaffolding`.
- Las tareas pequenas siguen siendo inmediatas.
- Las tareas costosas reciben una recomendacion clara antes de consumir el
  contexto del orquestador.
- Los workers reciben scope minimo y retornan envelopes compactos.
- `git pull` en el repositorio central actualiza el contrato global enlazado.
- Instalar, diagnosticar y desinstalar no pierde configuracion preexistente.
- No se versionan secretos ni se duplican skills gestionadas externamente.
