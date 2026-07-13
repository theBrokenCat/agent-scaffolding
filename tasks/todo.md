# Agent Scaffolding global v0.1 - Plan

**Goal:** Activar un workflow app-first global, reversible y compartido por Codex, Claude y Gemini sin modificar cada proyecto.
**Stack:** Markdown, shell POSIX, Git, GitHub CLI y tests de shell.

El prototipo documentado en los commits anteriores queda como evidencia. Este
plan sustituye su supuesto de instalacion por proyecto.

---

## Fase 0 - Seguridad y baseline

- [ ] Rotar las credenciales de Outline expuestas durante el inventario anterior. Diferido explicitamente por el usuario.
- [x] Inventariar instrucciones, skills, agentes y settings sin imprimir secretos.
- [x] Guardar backups fuera del repositorio durante la instalacion; checksums y destinos registrados.
- [x] Verificar estado de rama, PR y worktree.
- [x] Registrar baseline redactado; se incluye en el commit global de implementacion.

## Fase 1 - Contrato global y adaptadores

- [x] Reescribir el contrato para carga global y reglas locales opcionales.
- [x] Corregir los adaptadores de Claude y Gemini sin asignarles roles fijos.
- [x] Reducir `templates/` a contratos opcionales de proyecto nuevo.
- [x] Eliminar toda exigencia de instalar archivos en cada repositorio.
- [x] Incluir en el commit global de implementacion.

## Fase 2 - Router app-first y contexto

- [x] Añadir preflight de recomendacion y confirmacion selectiva.
- [x] Definir `app-direct`, delegacion, paralelo, relevo CLI e hibrido.
- [x] Definir aliases `economy`, `balanced`, `frontier` y retornos compactos.
- [x] Definir roles genericos, briefs de dominio y reglas de equipos/worktrees.
- [x] Incluir en el commit global de implementacion.

## Fase 3 - Instalador global reversible

- [x] Implementar `install`, `status`, `doctor` y `uninstall` con dry-run.
- [x] Enlazar instrucciones globales y elementos gestionados de forma individual.
- [x] Crear manifiesto, backup, rollback e idempotencia.
- [x] Cubrir instalacion, migracion, repeticion, drift y rollback con tests.
- [x] Incluir en el commit global de implementacion.

## Fase 4 - Skills, agentes y settings seguros

- [x] Crear registro curado de skills internas y externas.
- [x] Validar ownership, frontmatter, triggers, paths y duplicados.
- [x] Crear briefs de roles genericos portables entre hosts.
- [x] Versionar schemas/overlays allowlisted, nunca settings completos o secretos.
- [x] Incluir en el commit global de implementacion.

## Fase 5 - Validacion cruzada y GitHub

- [x] Probar hosts activos: Codex y Claude pasan; Gemini queda diferido por decision del usuario.
- [x] Probar preflight, degradacion sin teams y limites de contexto en Codex.
- [x] Ejecutar tests en HOME temporal y dry-run contra el HOME real.
- [x] Ejecutar doctor real, auditoria final de secretos y diff review.
- [x] Integrar la PR #1 autorizada y activar desde `main`.
- [x] Registrar validacion global en una rama post-merge.

## Fase 6 - Piloto y release

- [x] Piloto read-only en `personal-life` sin archivos locales obligatorios.
- [x] Medir friccion, consumo de contexto, degradaciones y fallos.
- [x] Sanear skills externas y repetir solo el smoke de coste Codex; Gemini queda fuera de scope.
- [ ] Solicitar autorizacion explicita para merge y despues para tag `v0.1.0`.
- [x] Commit: `docs: record v0.1 pilot`

---

## Review

Implementacion y merge completados; activacion global queda `managed current` y
`doctor` pasa. Codex carga el flujo global desde un directorio vacio y desde
`personal-life`; Claude tambien carga el contrato global tras autenticarse.
Gemini queda diferido por decision del usuario. Las skills invalidas fueron
reparadas o retiradas y la poda de plugins elimino el warning de presupuesto.
El coste residual fue aislado como contexto fijo del host: el smoke comparable
bajo solo 316 tokens. La rotacion de Outline sigue diferida. Merge y tag se
mantienen como autorizaciones humanas separadas.
