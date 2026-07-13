# Perfiles operativos

El router elige un perfil base por mutación y añade overlays ortogonales. Los
perfiles limitan autoridad, contexto y coste; no son personajes y nunca reemplazan
`AGENTS.md`. Sin `orchestrated`, cualquier perfil base usa el agente principal y,
como máximo, un subagente read-only acotado según `agents/README.md`.

## Perfiles base

### `solo`

- **Disparadores:** tarea no auditora que no cambia código ni configuración, como
  una edición documental o de estado operativo acotada.
- **Contexto:** instrucciones y evidencia mínima.
- **Permitido:** principal; como máximo un subagente read-only acotado.
- **Gates:** alcance, diff si escribe y verificación proporcional.
- **Documentación:** solo el documento solicitado.
- **Salida:** respuesta o cambio verificado y límites explícitos.

### `software`

- **Disparadores:** cualquier cambio de código, configuración, pruebas o artefacto
  de implementación, aunque sea un typo.
- **Contexto:** contrato, símbolos, dependencias directas, pruebas y estado Git.
- **Permitido:** editar dentro del scope; sin `orchestrated`, solo el principal
  escribe y puede usar como máximo un subagente read-only acotado.
- **Gates:** baseline, prueba de fallo para comportamiento, pruebas, lint/build
  aplicables y revisión del diff.
- **Documentación:** actualizar contratos solo cuando cambien.
- **Salida:** cambio mínimo, evidencia fresca y estado Git.

### `audit`

- **Disparadores:** análisis, revisión, diagnóstico, arquitectura, deuda o
  `/improve` sin mutación.
- **Contexto:** alcance, grafo o arquitectura, código y evidencia vigente.
- **Permitido:** lectura y recomendaciones; principal y, como máximo, un
  subagente read-only acotado. Es estrictamente read-only.
- **Gates:** hechos separados de inferencias, referencias verificables y ninguna
  alteración de archivos, índice o estado externo.
- **Documentación:** ninguna escritura, incluida la clasificación.
- **Salida:** hallazgos priorizados, evidencia, riesgos y plan accionable.

## Overlays

### `security`

- **Disparadores:** vulnerabilidad, amenazas, secretos, autenticación,
  autorización, criptografía o riesgo especializado.
- **Contexto:** superficie afectada, confianza, flujo de datos y controles.
- **Permitido:** skills especializados de seguridad, no un reviewer genérico;
  combina con cualquier perfil base y no concede escritura.
- **Gates:** evidencia reproducible, validación especializada, mínimo privilegio,
  redacción de secretos y aprobación para acciones intrusivas.
- **Documentación:** según sensibilidad y solo si el perfil base permite escribir.
- **Salida:** riesgo, evidencia, alcance, mitigación y riesgo residual.

### `production`

- **Disparadores:** producción, despliegues, migraciones, datos persistentes,
  credenciales, secretos o acciones difíciles de revertir.
- **Contexto:** estado observado, datos, runbook, observabilidad y permisos.
- **Permitido:** combinar con cualquier perfil base; no concede escritura ni
  ejecución. En `audit + production`, toda actuación permanece read-only.
- **Gates:** aprobación explícita para actuar, rollback verificable, protección y
  respaldo del estado persistente, manejo seguro de secretos y comprobación final.
- **Documentación:** runbook, cambio o incidente solo si el perfil base lo permite.
- **Salida:** estado observado, verificaciones, rollback y riesgos pendientes.

### `orchestrated`

- **Disparadores:** obligatorio para más de un subagente, cualquier worker
  escritor, ejecución paralela o equipo; nunca es default.
- **Contexto:** contrato compartido y brief mínimo por worker.
- **Permitido:** hasta tres workers sin delegación anidada, únicamente si se
  supera el umbral de `agents/README.md`; cumplirlo activa el nivel `deep`.
- **Gates:** dominios independientes, escrituras disjuntas, ahorro neto, propiedad
  explícita, aislamiento, integración del lead y cleanup.
- **Documentación:** decisiones duraderas solo si el perfil base permite escribir.
- **Salida:** retornos por worker, integración verificada y recursos cerrados.
