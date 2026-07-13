# Agent Scaffolding

Scaffolding personal mínimo para que Codex, Claude Code y Gemini CLI trabajen
con un contrato común, ligero y verificable. Su objetivo es reducir diferencias
entre herramientas sin convertir el repositorio en un sistema de orquestación
complejo.

## Estado actual

- `README.md`: guía de alcance, instalación y evolución manual.
- `AGENTS.md`: fuente canónica de las reglas compartidas.
- `CLAUDE.md`: adaptador con capacidades exclusivas de Claude Code.
- `GEMINI.md`: adaptador con capacidades exclusivas de Gemini CLI.

Estos archivos forman el contrato compartido de Fase 1. El repositorio todavía
no ofrece router, perfiles, políticas, plantillas ni automatización operativa.
La v0.1 no se considera lista hasta cerrar y verificar todas las fases del plan.

## Arquitectura objetivo

- `ROUTER.md`: selección de perfiles por tipo de tarea y riesgo.
- `profiles/`: contratos operativos activados bajo demanda.
- `agents/`: criterios y protocolos de delegación.
- `policies/`: límites de autoridad y políticas operativas.
- `templates/`: contratos para iniciar o ampliar proyectos.
- `.github/`: reglas y plantilla de pull request.

Esta estructura describe el destino previsto, no capacidades disponibles hoy.
Los adaptadores importan `AGENTS.md`; no copian sus reglas. Los perfiles y
directorios posteriores amplían el contrato solo cuando la tarea los necesita.

## Instalación manual

1. Clona este repositorio en una ubicación estable y selecciona una versión o
   commit concreto como origen.
2. Registra el repositorio y el tag o SHA de origen en la documentación existente
   del proyecto de destino.
3. Elige y registra una línea exacta: `Git publication mode: local-only` o
   `Git publication mode: autonomous-pr`. Se recomienda `autonomous-pr` para este
   flujo personal; si no registras ningún modo, se aplica `local-only`.
4. Copia `AGENTS.md` al directorio raíz del proyecto de destino.
5. Copia `CLAUDE.md`, `GEMINI.md` o ambos según las herramientas utilizadas.
6. Conserva `@AGENTS.md` como primera línea operativa de cada adaptador.
7. Mantén las reglas propias del proyecto en su documentación local; no las
   sustituyas ni las dupliques en los adaptadores.
8. Revisa el diff y confirma que las herramientas cargan el contexto antes de
   empezar trabajo real.

Para actualizar una instalación, compara la versión registrada con el nuevo tag
o commit, incorpora manualmente solo los cambios comunes aplicables y conserva
las reglas locales. Registra después la nueva referencia de origen. No reemplaces
archivos completos sin revisar el diff.

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
