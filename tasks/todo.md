# Agent Scaffolding global v0.1 - Plan

**Goal:** Activar un workflow app-first global, reversible y compartido por Codex, Claude y Gemini sin modificar cada proyecto.
**Stack:** Markdown, shell POSIX, Git, GitHub CLI y tests de shell.

El prototipo documentado en los commits anteriores queda como evidencia. Este
plan sustituye su supuesto de instalacion por proyecto.

---

## Fase 0 - Seguridad y baseline

- [ ] Rotar las credenciales de Outline expuestas durante el inventario anterior.
- [ ] Inventariar instrucciones, skills, agentes y settings sin imprimir secretos.
- [ ] Guardar checksums, destinos y backups fuera del repositorio.
- [ ] Verificar estado de rama, PR y worktree.
- [ ] Commit: `chore: record migration baseline`

## Fase 1 - Contrato global y adaptadores

- [ ] Reescribir el contrato para carga global y reglas locales opcionales.
- [ ] Corregir los adaptadores de Claude y Gemini sin asignarles roles fijos.
- [ ] Reducir `templates/` a contratos opcionales de proyecto nuevo.
- [ ] Eliminar toda exigencia de instalar archivos en cada repositorio.
- [ ] Commit: `docs: define global agent contract`

## Fase 2 - Router app-first y contexto

- [ ] Añadir preflight de recomendacion y confirmacion selectiva.
- [ ] Definir `app-direct`, delegacion, paralelo, relevo CLI e hibrido.
- [ ] Definir aliases `economy`, `balanced`, `frontier` y retornos compactos.
- [ ] Definir roles genericos, briefs de dominio y reglas de equipos/worktrees.
- [ ] Commit: `docs: define app first orchestration`

## Fase 3 - Instalador global reversible

- [ ] Implementar `install`, `status`, `doctor` y `uninstall` con dry-run.
- [ ] Enlazar instrucciones globales y elementos gestionados de forma individual.
- [ ] Crear manifiesto, backup, operaciones atomicas e idempotencia.
- [ ] Cubrir instalacion, conflicto, repeticion y rollback con tests.
- [ ] Commit: `feat: add global scaffolding installer`

## Fase 4 - Skills, agentes y settings seguros

- [ ] Crear registro curado de skills internas y externas.
- [ ] Validar frontmatter, triggers, herramientas y duplicados.
- [ ] Crear roles nativos solo donde el host los soporte.
- [ ] Versionar schemas/overlays allowlisted, nunca settings completos o secretos.
- [ ] Commit: `feat: add capability registry`

## Fase 5 - Validacion cruzada y GitHub

- [ ] Probar los tres hosts desde directorio vacio, repo y subdirectorio.
- [ ] Probar precedencia local, preflight, degradaciones y limites de contexto.
- [ ] Ejecutar tests, doctor, auditoria de secretos y diff review.
- [ ] Actualizar y revisar la draft PR sin hacer merge.
- [ ] Commit: `test: validate global activation`

## Fase 6 - Piloto y release

- [ ] Piloto aislado en `personal-life` sin archivos locales obligatorios.
- [ ] Medir friccion, consumo de contexto, delegaciones y fallos.
- [ ] Corregir solo problemas observados y repetir gates afectados.
- [ ] Solicitar autorizacion explicita para merge y despues para tag `v0.1.0`.
- [ ] Commit: `docs: record v0.1 pilot`

---

## Review

<!-- Se completa durante la ejecucion con evidencia real, bloqueos y riesgo residual. -->
