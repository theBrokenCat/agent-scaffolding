# Agent Scaffolding

Scaffolding personal mínimo para que Codex, Claude Code y Gemini CLI trabajen
con un contrato común, ligero y verificable. Su objetivo es reducir diferencias
entre herramientas sin convertir el repositorio en un sistema de orquestación
complejo.

## Estado actual

`v0.1` es una candidata de validación, no un tag `v0.1.0`: el piloto aún no
se ha ejecutado y no hay autorización para hacer merge. La evidencia de cierre
de Fase 5, incluidos resultados, bloqueos, riesgo residual y siguiente gate,
está en [`tasks/todo.md`](tasks/todo.md).

- `README.md`: guía de alcance, instalación y evolución manual.
- `AGENTS.md`: fuente canónica de las reglas compartidas.
- `ROUTER.md`: clasificación determinista por mutación, riesgo y delegación.
- `profiles/README.md`: contratos base y overlays operativos.
- `agents/README.md`: límites y protocolo de delegación.
- `policies/README.md`: índice único de políticas operativas.
- `CLAUDE.md`: adaptador con capacidades exclusivas de Claude Code.
- `GEMINI.md`: adaptador con capacidades exclusivas de Gemini CLI.
- `templates/README.md`: contrato canónico de instalación de proyectos.
- `.github/README.md`: contrato de configuración y operación en GitHub.
- `.github/pull_request_template.md`: plantilla de evidencia para pull requests.

Estos archivos forman el contrato compartido disponible. El repositorio no
ofrece automatización operativa.
La carga selectiva del router es obligatoria. El host no debe considerarse
ajustado al presupuesto si carga plugins o skills globales; la v0.1 no se
considera lista hasta ejecutar el piloto y recibir autorización explícita.

## Arquitectura objetivo

- `ROUTER.md`: selección de perfiles por tipo de tarea y riesgo.
- `profiles/`: contratos operativos activados bajo demanda.
- `agents/`: criterios y protocolos de delegación.
- `policies/`: límites de autoridad y políticas operativas.
- `templates/`: contratos para iniciar o ampliar proyectos.
- `.github/`: reglas y plantilla de pull request.

Router, perfiles, delegación, políticas, contrato de instalación y contrato de
GitHub ya están disponibles. Los adaptadores importan `AGENTS.md`; no copian sus
reglas. Los perfiles amplían el contrato solo cuando la tarea los necesita.

## Instalación manual

La lista canónica, la configuración obligatoria, las extensiones bajo demanda y
el rollback viven únicamente en [`templates/README.md`](templates/README.md).
Sigue ese contrato completo; este README no mantiene una segunda lista parcial.

Instala desde un SHA base limpio en una rama o worktree dedicada. Cuando un
archivo ya exista, especialmente `README.md`, `.gitignore` o instrucciones de
agentes, compara su contenido y fusiona las reglas aplicables. Nunca reemplaces
archivos existentes a ciegas. Revisa el diff y confirma que las herramientas
cargan el contexto antes de empezar trabajo real.

Para actualizar una instalación, compara la versión registrada con el nuevo tag
o commit, incorpora manualmente solo los cambios comunes aplicables y conserva
las reglas locales. Registra después la nueva referencia de origen. No reemplaces
archivos completos sin revisar el diff.

El repositorio es siempre la fuente canónica para estado, implementación, ADRs y
runbooks específicos. Outline conserva conocimiento transversal o histórico y
enlaza esos documentos versionados en lugar de duplicarlos.

Ejecuta durante la instalación solo verificaciones locales, seguras y
autorizadas. Registrar comandos de setup, red, bases de datos o producción no
autoriza ejecutarlos; documenta cualquier omisión con su razón y riesgo residual.

Para operar en GitHub, sigue [`.github/README.md`](.github/README.md). Considera
protección técnica solo un ruleset cuyo soporte y estado activo se hayan
comprobado; en cualquier otro caso, describe las medidas como controles
procedimentales.

La instalación es deliberadamente manual en v0.1. Permite observar qué partes
se repiten de verdad antes de introducir un instalador o sincronización.

## Evolución

1. Parte de un caso observado: una tarea repetida, un fallo recurrente o una
   restricción que no se está cumpliendo.
2. Decide si corresponde al contrato común, a un adaptador, a un perfil o a una
   política.
3. Haz el cambio mínimo y evita duplicar reglas entre capas.
4. Verifica los escenarios afectados en una rama corta. Usa draft PR solo con
   `autonomous-pr` o autorización explícita.
5. Pilota el cambio en un proyecto antes de promoverlo como convención general.

No se añaden scripts, hooks, plantillas, agentes, directorios ni otra
automatización sin un caso real que demuestre su necesidad. Una preferencia
hipotética no basta.
