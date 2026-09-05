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

## v0.2 - Fase 2: orquestacion de subagentes y routing de modelos

- [x] Definir dos curvas de modelo con effort explicito y sacar a Terra del default.
- [x] Anadir los dos gates semanticos de escalada a la curva Sol.
- [x] Asignar alias, effort y disparador de escalada a cada rol canonico.
- [x] Sustituir `deep = 3 workers` por el presupuesto real de concurrencia.
- [x] Fundir el protocolo de orquestacion en el contrato y dejar en el registro
      solo un puntero.
- [x] Corregir las contradicciones de `spec-reviewer` y `quality-reviewer`.
- [x] Materializar los roles por host y instalarlos como unidad separada.
- [x] Cubrir con tests los invariantes del contrato y el generador.
- [x] Registrar el diseno del piloto A/B con criterios pre-registrados.
- [x] Ejecutar la paridad en runtime por host (`tests/runtime-parity.md`).
      Codex pasa en los cuatro roles; Claude falla por id de modelo no portable.
- [x] Resolver el alias por host en el model map y verificar Claude por despacho
      real: el modelo lo fija la definicion; el effort sigue sin ser observable.
- [x] Materializar un archivo por estado escalado y verificar los nueve estados
      por despacho real, incluido `quality-reviewer-critical` en sol / max.
- [x] Prohibir el fork de turnos cuando el alias importe y separar la unidad de
      agentes por host.
- [ ] Ejecutar el piloto A/B y registrar sus mediciones.
- [ ] Revisar `frontier`/`critical` en Claude si se levanta el limite de gasto de
      Fable 5.1, hoy el unico techo que impide usarlo.

Los objetivos de la fase (agentes 19 -> 8-11, reloj 38 h -> 14-22 h, coste
-40/65 %) son stretch registrados, no resultados: ninguna cifra esta medida
todavia.

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

## Issue 32 - Contratos coherentes y roles por necesidad

- [x] Alcance autorizado y baseline congelada; ver `tasks/phases/phase-32-role-contracts.md`.
- [x] Unificar retorno y generar fichas autocontenidas.
- [x] Distinguir revisión desactivada/ejecutada y seleccionar roles por necesidad.
- [x] Regresiones, ocho suites, review independiente sin hallazgos y draft PR #33.
- [x] PR #33 integrada: verificado el 05/09/2026, commit `bf5bca0`.
- [ ] Instalación global: pendiente; no ejecutada en este trabajo.

## Issue 34 - Simplificación y continuidad

- [x] Eliminar reglas duplicadas y afirmaciones de capacidad no demostradas.
- [x] Separar aceptación, descomposición y escalada; registrar relevo por objetivo.
- [x] Corregir Broken pipe; ocho suites, review independiente y CI verdes; draft PR #35.
- [ ] Merge de #35 e instalación global: requieren autorización.
- Plan/evidencia: `tasks/phases/phase-34-simplify-orchestration.md`.
