# Agent Scaffolding - Diseño

## Objetivo

Crear un repositorio independiente que proporcione a Codex, Claude Code y
Gemini CLI un mismo flujo de trabajo personal, ligero y verificable. El sistema
debe reducir desorganización, mantener cada proyecto sincronizado con GitHub y
activar contexto, documentación y agentes adicionales solo cuando aporten valor.

## Principios

- Una sola fuente de verdad para reglas comunes: `AGENTS.md`.
- Adaptadores pequeños para Claude y Gemini, sin duplicar políticas.
- Un agente por defecto; delegación solo para trabajo realmente independiente.
- GitHub Flow con `main` protegida, ramas cortas y pull requests.
- Commits automáticos por cambio lógico; nunca push directo a `main`.
- Estado operativo en el repositorio; conocimiento transversal en Outline.
- Descubrimiento de código mediante `codebase-memory-mcp` antes de búsquedas de texto.
- Perfiles y archivos opcionales generados bajo demanda.
- Bucles de revisión, CI y corrección con límites explícitos.
- Ponytail para evitar estructura y automatización especulativas.

## Arquitectura

```text
agent-scaffolding/
├── README.md
├── AGENTS.md
├── CLAUDE.md
├── GEMINI.md
├── ROUTER.md
├── profiles/README.md
├── agents/README.md
├── policies/README.md
├── templates/README.md
└── .github/
    ├── README.md
    └── pull_request_template.md
```

No se crearán scripts, hooks, roles individuales ni plantillas físicas en la
primera versión. Solo se añadirán después del piloto cuando exista una tarea
manual repetida o un fallo que requiera enforcement mecánico.

## Enrutamiento

La precedencia será:

1. Instrucción explícita del usuario.
2. Restricciones e instrucciones del proyecto activo.
3. Perfil activado por tipo de trabajo o riesgo.
4. Perfil `software` para cambios normales de código.
5. Perfil `solo` como valor por defecto.

Los perfiles son contratos operativos, no personajes. La primera versión
incluye `solo`, `software`, `audit`, `security`, `production` y `orchestrated`.
`production` y `security` pueden añadir gates sobre `software`.

## Delegación

La escalera de menor a mayor coste será:

1. Agente principal.
2. Un subagente para una investigación acotada.
3. Subagentes paralelos para dominios independientes.
4. Equipo coordinado cuando los trabajadores necesiten comunicarse.

Los equipos empiezan con un máximo de tres trabajadores. Antes de lanzarlos se
declaran tarea, dependencias, archivos en propiedad, modelo de coste, worktree y
criterio de finalización. Cada escritor trabaja en rama y worktree propios. El
agente principal conserva los contratos compartidos, integra y verifica.

## Flujo Git

1. Actualizar referencias remotas y `main` mediante fast-forward.
2. Crear rama corta o worktree desde `origin/main`.
3. Verificar baseline antes de editar.
4. Implementar y verificar cambios lógicos pequeños.
5. Crear Conventional Commits en inglés.
6. Subir la rama tras cada checkpoint verde y mantener una draft PR.
7. Resolver revisión y CI con bucles acotados.
8. Solicitar confirmación para merge, salvo auto-merge preautorizado.
9. Hacer squash merge, actualizar `main` y eliminar rama/worktree.

El agente queda autorizado para crear ramas y worktrees, hacer commits, subir
ramas, abrir o actualizar PRs y atender CI. Nunca puede hacer push directo a
`main`, force-push no autorizado, merge sin autorización ni despliegue de
producción implícito.

## Contexto y documentación

`codebase-memory-mcp` es la primera vía para arquitectura, símbolos, llamadas e
impacto. Outline se consulta cuando hacen falta decisiones anteriores,
documentación transversal o notas de despliegue. Solo se modifica por petición
explícita. El repositorio conserva el estado operativo y las decisiones de
implementación; no se duplican sesiones completas en Outline.

El proyecto generado empieza únicamente con instrucciones de agentes,
`README.md`, `.gitignore` y plantilla de PR. `tasks/active.md`,
`tasks/lessons.md`, ADRs, incidentes y runbooks aparecen cuando el perfil o la
duración del trabajo los justifican.

## Bucles y límites

- Descubrimiento: una pasada inicial y una ampliación como máximo.
- Revisión: dos rondas; después se escala el desacuerdo o bloqueo.
- CI: tres intentos de corrección; después diagnóstico y parada explícita.
- PR: dos rondas de feedback antes de replantear alcance o diseño.
- Lecciones: solo errores repetidos, caros o con impacto duradero.
- Equipos: sin delegación anidada y con cierre obligatorio de trabajadores.

## Compatibilidad entre plataformas

`AGENTS.md` contiene el contrato común y las condiciones de carga. `CLAUDE.md`
importa `@AGENTS.md` y añade únicamente Plan Mode, skills, subagentes, equipos,
hooks y comprobación mediante `/memory`. `GEMINI.md` importa `@AGENTS.md` y
añade memoria jerárquica, recarga de contexto y protocolo de relevo cuando una
capacidad no esté disponible. Ninguna plataforma queda limitada a un rol fijo.

## Criterios de éxito de v0.1

- Las tres herramientas reciben las mismas reglas comunes sin duplicación.
- Seis escenarios de presión seleccionan el perfil correcto.
- Una tarea pequeña no genera archivos ni agentes innecesarios.
- Una tarea paralela declara propiedad de archivos y worktrees antes de escribir.
- Todo cambio termina en commit, rama remota y PR verificable.
- Las políticas indican claramente cuándo usar repositorio, Outline y MCP.
