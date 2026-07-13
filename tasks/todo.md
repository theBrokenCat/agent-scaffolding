# Agent Scaffolding v0.1 - Plan

**Goal:** Crear un scaffolding personal mínimo y compartido por Codex, Claude y Gemini.
**Stack:** Markdown, Git, GitHub CLI y shell POSIX solo si el piloto justifica scripts.

---

## Fase 1 - Contrato común y adaptadores

- [x] Crear `README.md` y explicar instalación, alcance y mantenimiento.
- [x] Crear `AGENTS.md` como fuente canónica.
- [x] Crear adaptadores mínimos `CLAUDE.md` y `GEMINI.md`.
- [x] Verificar que no existan reglas comunes duplicadas.
- [x] Commit: `docs: add shared agent contract`

## Fase 2 - Router, perfiles y delegación

- [x] Crear `ROUTER.md` con precedencia y tabla de decisión.
- [x] Crear `profiles/README.md` con seis perfiles y gates.
- [x] Crear `agents/README.md` con escalera de delegación y protocolo de equipos.
- [x] Validar seis escenarios de enrutamiento manualmente.
- [x] Commit: `docs: define workflow routing and delegation`

## Fase 3 - Políticas operativas

- [ ] Crear `policies/README.md`.
- [ ] Definir Git/GitHub, tokens, MCP, Outline, seguridad y documentación.
- [ ] Acotar bucles, autoridad automática y condiciones de parada.
- [ ] Comprobar que ninguna política contradiga los adaptadores.
- [ ] Commit: `docs: add operational policies`

## Fase 4 - Contrato de proyecto y pull requests

- [ ] Crear `templates/README.md` con estructura mínima y extensiones bajo demanda.
- [ ] Crear `.github/README.md` con reglas del repositorio.
- [ ] Crear `.github/pull_request_template.md`.
- [ ] Verificar que el template no genere directorios opcionales.
- [ ] Commit: `docs: add project and pull request contracts`

## Fase 5 - Validación, GitHub y piloto

- [ ] Revisar enlaces, imports, nombres y límites de contexto.
- [ ] Ejecutar escenarios de presión y registrar resultados.
- [ ] Crear repositorio privado de GitHub y publicar la rama.
- [ ] Abrir PR de v0.1 y verificar su flujo completo.
- [ ] Seleccionar un proyecto piloto sin modificarlo todavía.
- [ ] Commit: `test: validate scaffolding workflow`

---

## Review

<!-- Se completa después de implementar y pilotar v0.1. -->
