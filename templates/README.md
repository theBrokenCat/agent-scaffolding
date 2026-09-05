# Contrato opcional para proyectos

`~/agent-scaffolding` se activa globalmente. Ningun proyecto necesita instalar
`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, el router, perfiles, agentes o politicas.
Este directorio solo define que crear cuando el usuario pide iniciar o ampliar
un proyecto.

## Proyecto nuevo

Empieza con lo minimo que el proyecto necesita:

- `README.md` con objetivo, setup y comandos realmente disponibles;
- `.gitignore` ajustado al stack y, si se usan worktrees dentro del proyecto,
  la ruta correspondiente;
- instrucciones locales solo cuando aporten hechos, comandos o restricciones
  que el contrato global no puede conocer;
- `.github/pull_request_template.md` solo si el proyecto usa GitHub y una
  plantilla reduce omisiones reales.

No existe un schema `agent_scaffolding`, una lista de archivos instalados ni un
modo de publicacion obligatorio. La ausencia de instrucciones locales es valida.
No copies el contrato global dentro del proyecto.

## Instrucciones locales

Cuando sean utiles, crea solo el archivo que el host soporte en el nivel mas
cercano al scope: `AGENTS.md`, `CLAUDE.md` o `GEMINI.md`. Conserva contenido
existente y anade un archivo anidado solo si un subarbol necesita reglas
distintas. Las reglas locales pueden precisar el proyecto, pero no ampliar
permisos superiores.

Contenido apropiado: arquitectura, comandos de setup/test/lint/build, limites de
scope, owners, baseline conocido y restricciones de datos o despliegue. No
incluyas secretos, settings completos, preferencias de UI ni copias de politicas
globales.

## Extensiones bajo demanda

Crea ADRs para decisiones dificiles de revertir, runbooks para operaciones
repetibles, incidentes para impacto real y tareas persistentes para trabajo
multisesion. No generes directorios vacios, backlog duplicado, agentes, hooks,
scripts o plantillas por anticipado. Para trabajo multisesion usa el
[relevo por objetivo](../agents/README.md#trabajo-multisesion) sobre los issues o
documentos existentes; no crees un registro paralelo.

## Criterio de cierre

Revisa el diff, conserva archivos existentes y ejecuta solo verificaciones
locales, seguras y autorizadas. Documenta comandos omitidos y riesgo residual.
La inicializacion no autoriza red de aplicacion, bases de datos, merge, deploy ni
produccion. El ciclo normal de feature branch, checkpoint push y draft PR se rige
por el contrato global; no adquiere permisos adicionales por este template.
