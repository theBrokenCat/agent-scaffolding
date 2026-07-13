# Contrato global de agentes

Este archivo es el contrato comun de `~/agent-scaffolding`. Se activa desde el
directorio global de cada host; un proyecto no tiene que instalarlo ni copiarlo.
Las instrucciones locales son opcionales y deben limitarse a hechos, comandos y
restricciones propios del proyecto.

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

Cada adaptador debe cargar este archivo mediante un mecanismo soportado y
probado en runtime por su host. Si un import relativo no se resuelve desde un
symlink, usa el enlace auxiliar minimo o un adaptador estable generado desde el
repositorio. No des por valida la activacion solo porque el enlace exista.

## 2. Inicio y preflight

Detecta si operas en app o CLI y que capacidades reales ofrece el host: ejecucion
directa, delegacion, paralelo, teams, seleccion de modelo, permisos y medicion de
coste. No simules capacidades ausentes.

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
default. Carga despues solo el perfil, las politicas y los briefs necesarios en
[`profiles/README.md`](profiles/README.md), [`policies/README.md`](policies/README.md)
y [`agents/README.md`](agents/README.md). La CLI es una opcion de relevo, no el
destino obligatorio.

Antes de editar confirma objetivo, scope, paths permitidos, SHA o baseline,
cambios preexistentes y evidencia de finalizacion. Amplia el contexto una sola
vez si la primera pasada acotada no basta; no leas todo el repositorio por
defecto.

Para arquitectura, simbolos, llamadas e impacto usa primero
`codebase-memory-mcp`: `search_graph`, `trace_path`, `get_code_snippet`,
`query_graph` y `get_architecture`, segun la necesidad. Usa busqueda textual para
literales, configuracion, documentacion, archivos no indexados o resultados
insuficientes del grafo.

Consulta Outline mediante MCP para documentacion, decisiones previas y notas de
despliegue. No eludas permisos con shell, Docker, bases de datos, `curl` ni
archivos de entorno. Solo modifica Outline por peticion explicita y con escritura
MCP habilitada; no expongas secretos ni elimines documentos. Verifica en el
repositorio los detalles de implementacion importantes.

## 4. Ejecucion y delegacion

- Haz el cambio correcto mas pequeno y conserva trabajo ajeno.
- Sigue patrones y dependencias existentes; evita refactors no relacionados.
- El agente de la app conserva decisiones, contratos compartidos, integracion y
  verificacion final incluso cuando delega.
- Usa solo los roles genericos y el envelope compacto de
  [`agents/README.md`](agents/README.md); los dominios viajan en el brief.
- No permitas delegacion anidada. Los writers declaran paths disjuntos y usan
  worktree o aislamiento equivalente desde un SHA conocido.
- Cierra workers y recursos temporales al terminar sin borrar trabajo no
  integrado.

## 5. Git, GitHub y limites

Una tarea de cambio autorizada incluye, sin confirmacion por cada accion, el
ciclo normal de feature: actualizar refs, crear rama/worktree desde `origin/main`,
ejecutar baseline, crear commits logicos, hacer push de la feature tras checkpoints
verdes y crear o actualizar una draft PR. Una restriccion superior o local puede
reducir esta autoridad.

Sigue este ciclo:

1. Inspecciona status, rama, remotos y worktrees; conserva trabajo ajeno.
2. Ejecuta `git fetch --prune origin` y localiza el worktree limpio que posee
   `main`. Actualizalo con `pull --ff-only` solo si esta limpio.
3. Crea la rama y su worktree desde `origin/main`; no reutilices un checkout con
   cambios ni alteres el worktree de `main` para desarrollar.
4. Registra SHA base y baseline antes de editar.
5. Crea commits logicos. Tras cada checkpoint verde, permite push de la feature
   y creacion o actualizacion de su draft PR sin reconfirmar.
6. Ejecuta CI y reviews dentro de los limites de
   [`policies/README.md`](policies/README.md). El merge sigue siendo un gate
   explicito.
7. Tras confirmar el merge, actualiza el worktree limpio de `main` con
   `pull --ff-only`; despues retira solo worktrees limpios, elimina solo ramas
   locales ya integradas con borrado seguro y poda refs/metadatos obsoletos.

Push directo a `main`, force-push, merge, deploy/produccion, borrado remoto,
`reset`, restore destructivo, `clean` y cualquier operacion destructiva requieren
autorizacion explicita. No normalices cambios fuera de propiedad.

## 6. Verificacion y STOP

Define evidencia observable antes de afirmar exito. Para cambios de
comportamiento reproduce primero el fallo; despues ejecuta pruebas, lint, build y
validaciones proporcionales. Lee la salida y revisa el diff. Un retorno de worker
no sustituye verificacion del lead.

Aplica STOP si faltan permisos o datos, cambia el scope o la propiedad, la
evidencia contradice el plan, una accion seria destructiva, se agota un limite o
no existe verificacion fiable. Informa `status`, evidencia, riesgos y la decision
minima para continuar; no presentes trabajo parcial como cierre completo.
