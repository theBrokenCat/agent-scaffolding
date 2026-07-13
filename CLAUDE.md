@AGENTS.md

# Adaptador de Claude Code

## Skills y planificación

- Descubre y carga los skills aplicables antes de actuar. Prioriza skills de
  proceso sobre skills de implementación y evita cargar capacidades irrelevantes.
- Usa Plan Mode para tareas no triviales, cambios de varias etapas o decisiones
  con impacto amplio. Sal de Plan Mode antes de ejecutar el plan aprobado.

## Subagentes y equipos

- Elige subagentes para encargos acotados e independientes.
- Usa equipos cuando los trabajadores necesiten coordinarse entre sí. Mantén en
  el agente principal la integración y las comprobaciones exigidas por `AGENTS.md`.

## Hooks

Usa hooks como enforcement mecánico de reglas deterministas ya acordadas. No los
uses para sustituir revisión, criterio técnico ni autorización humana.

## Memoria

Usa `/memory` para comprobar que `AGENTS.md`, las instrucciones locales y el
contexto esperado están cargados antes de depender de ellos.
