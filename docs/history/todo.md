# Historical scaffolding task record

Snapshot of `tasks/todo.md` at `158f533`. This is evidence, not current instructions
or live status. Follow [the task index](../../tasks/todo.md) for current work.
Paths in historical prose retain their original context unless linked here.

---

# Agent Scaffolding global v0.1 - Plan

## Estado registrado — historico

Seguimiento canonico: [Issue #51 — principal, aprobaciones y cierre](https://github.com/theBrokenCat/agent-scaffolding/issues/51).
Estado, checkout, evidencia, bloqueos y siguiente accion se mantienen alli;
este archivo es un indice y no replica la cabecera mutable.

El cambio delimita quien escribe en Outline, usa decisiones estructuradas del
host cuando estan permitidas y completa cierre de CI/estado y smoke de entorno.
Mantiene cuatro roles, retorno comun y gates humanos. No cambia Penthos ni
instala instrucciones globales durante la preparacion del diff.
#50 (skills/README.md y skills/registry.yaml) sigue en su worktree independiente.

## Entrega #46 — historia anterior a #51

**Resultado:** #46, reducir contexto automatico y mejorar reaperturas, estado y esperas.
**Estado:** candidato verificado y aprobado; usuario autoriza publicacion, merge e instalacion global. Cierre de entrega en el issue #46.
**Responsable:** lead de esta tarea; reviewer independiente de solo lectura.
**Checkout:** `.worktrees/46-context`, `feat/46-context`, base `cec18ac02bea6fab36d8d71f8100468510888ac0`.
**Verificacion vigente:** ocho suites verdes; 20 renders verificados, cuatro fichas intactas; diff-check limpio.
**Bloqueo:** ninguno. **Siguiente accion:** consultar el [cierre de entrega](https://github.com/theBrokenCat/agent-scaffolding/issues/46) para estado de merge, instalacion y evidencia; cambios posteriores requieren su propio alcance.
**Autoridad:** solo scaffolding; usuario autorizo instalar e integrar el 08/09/2026. No tocar Penthos ni su tarea.
**Evidencia:** [inventario y comparacion](#issue-46--contexto-y-coordinacion); historia anterior debajo.

#44 se integro en PR #45 (`cec18ac`); su [registro](../../tasks/44-operational-contract.md)
conserva el estado historico anterior a publicacion. No es trabajo pendiente de #46.

## Issue 46 — Contexto y coordinacion

Issue: https://github.com/theBrokenCat/agent-scaffolding/issues/46.
Diseno autorizado: nucleo comun pequeno en AGENTS; procedimientos del lead en las
politicas/manual existentes; workers autocontenidos mediante ficha, guardas y
retorno comun. Sin otro framework, dependencia ni documento obligatorio.

### Que se carga y que se consulta

| Entrada | Carga observada / mecanismo | Tratamiento |
| --- | --- | --- |
| AGENTS global | Symlink gestionado en Codex; import `@AGENTS.md` en adaptadores Claude/Gemini | Nucleo obligatorio reducido; conserva autoridad y gates. |
| Instrucciones locales | El host las suministra segun proyecto/checkout; el log auditado incluia contexto local junto al global | No se editan proyectos consumidores. No copiar de nuevo en el brief. |
| Rol seleccionado | `role_instructions` incorpora guardas, ficha y solo `Envelope de retorno`; diez estados por host, cuatro roles | Reducir texto repetido; conservar modelo/effort, autoridad y ocho campos. |
| Router, politicas, manual del lead | Enlaces Markdown, no imports del generador | Consultar la seccion requerida antes de la accion afectada. |
| Skills, herramientas, plugins, memoria y contexto del host | Catalogos/metadata pueden ser inyectados por la plataforma; bodies se consultan cuando aplican | No cambiar configuracion global ni atribuir esa carga al brief del lead. |
| Historia de tarea / turnos heredados | Depende del host y del fork usado | Brief con delta y evidencia enlazada; no copiar historiales. |

Comprobado mediante symlinks existentes, adaptadores, `scripts/gen-agents` y
metadatos del log de #72 ya auditado. Esto no prueba que todos los hosts carguen
igual ni elimina una posible doble inyeccion global/local. Durante la validacion
del diff no se instalo el candidato ni se relanzaron sesiones del consumidor.

### Verificacion y medida

Evidencia de ejecucion: `/private/tmp/scaffolding-46.jLBEv4/` (raiz exclusiva).
Baseline: las ocho suites existentes pasan sobre `cec18ac`. La regresion nueva
del generador fallo primero por ausencia de la guarda de publicacion; el candidato
debe conservarla en los veinte renders junto con roles y retorno canonicos.
Comparacion: `git archive cec18ac` a la raiz propia; render de ambos snapshots con
el mismo `settings/schemas/model-map.example.yaml`, hosts codex y claude.
Se cuentan bytes UTF-8 y palabras separadas por whitespace: TOML decodificado
(`developer_instructions`), Markdown Claude sin frontmatter, fuente para AGENTS y
adaptadores. Datos en `context-sizes.json`:

| Componente | Bytes antes | Bytes despues | Reduccion |
| --- | ---: | ---: | ---: |
| AGENTS.md | 10540 | 5826 | 44,7 % |
| Adaptador Claude (sin sumar su import) | 966 | 554 | 42,7 % |
| Adaptador Gemini (sin sumar su import) | 894 | 414 | 53,7 % |
| Worker implementer-frontier, Codex | 3975 | 3438 | 13,5 % |
| Suma 10 definiciones Codex | 41788 | 35984 | 13,9 % |
| Suma 10 definiciones Claude | 42748 | 36944 | 13,6 % |

AGENTS pasa de 1476 a 733 palabras; el ejemplo worker de 564 a 472. La suma de
definiciones compara el catalogo, no implica que un worker cargue los diez cuerpos.
Las politicas crecen al recibir procedimientos antes automaticos. Tamano de
los seis documentos juntos: 39235 -> 39747 bytes (+1,3 %); leerlos todos de nuevo
anularia la ventaja. La reduccion se concentra en las entradas automaticas y
los roles, con seleccion de secciones para el resto. Metadatos de
modelo/effort y restricciones de herramientas iguales en los 20 renders;
cuatro fichas fuente identicas a la base. Ocho suites finales verdes (se repitieron
solo gen_agents y orchestration tras corregir expectativas literales y un enlace
trasladado); diff-check limpio. Escenarios revisados en tests/operational-scenarios.md.

Son tamanos estaticos de instrucciones, no tokens facturados ni ahorro total.
No incluyen catalogos del host, prompt local, lecturas posteriores, razonamiento,
cache o numero de turnos. Mover texto a politicas solo reduce la carga cuando se
respeta la consulta selectiva. No es un benchmark de calidad o rendimiento.

Cambios operativos: diagnostico causal y reorganizacion antes de pedir ampliacion
de rondas; cabecera vigente primero; evidencia historica enlazada; esperar eventos
sin sondeos redundantes, cumpliendo limites y comunicacion del host.
Revision completada: `context_review`, sesion nueva por independencia. Modelo
observado en turn_context: `gpt-5.6-sol`, `xhigh`, tarea
`01a08231-ed46-7ba0-927a-0e383b24ebdf`. Snapshot de los 11 archivos de contrato,
generador y tests en `review-snapshot.sha256`; solo este registro recibe resultados
mientras se revisa. El lead verifica renders y mantiene el estado; sin delegacion
de checkpoints. Primera review: 0 Blocking / 2 Important, enlace de Outline
incorrecto y concesion Git preparatoria implicita. Corregidos en un solo lote;
contract/orchestration y diff-check repetidos con PASS. Relectura de esos dos
puntos sobre `review-snapshot-v2.sha256`: PASS, 0 Blocking / 0 Important;
los 11 checksums coinciden. Consumo total no medido. Este cierre del registro
solo incorpora resultados, no modifica el candidato revisado.

---

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
- [x] Instalación global verificada el 05/09/2026 sobre `48fa15a`; Codex y Claude comprobados en sesiones nuevas.

## Issue 34 - Simplificación y continuidad

- [x] Eliminar reglas duplicadas y afirmaciones de capacidad no demostradas.
- [x] Separar aceptación, descomposición y escalada; registrar relevo por objetivo.
- [x] Corregir Broken pipe; ocho suites, review independiente y CI verdes; draft PR #35.
- [x] PR #35 integrada e instalación global verificada el 05/09/2026 (`48fa15a`).
- Plan/evidencia: `tasks/phases/phase-34-simplify-orchestration.md`.


## Issue 30 - Consultas desde worktrees

Contrato y evidencia del relevo: `tasks/30-doctor-context.md`.
Estado de entrega: https://github.com/theBrokenCat/agent-scaffolding/issues/30
