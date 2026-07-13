# Router de trabajo

## Propósito y precedencia

El router selecciona el contrato mínimo sin conceder autoridad adicional. Aplica
primero la precedencia superior de `AGENTS.md`: usuario y proyecto, configuración
activa, clasificación de esta tarea, `software` y por último `solo`. Los perfiles
son contratos, no personajes.

## Clasificación determinista

Responde en orden, sin leer todos los perfiles:

1. ¿Es read-only, incluido análisis, revisión o `/improve`?
2. ¿Cambia código, configuración o artefactos de implementación?
3. ¿Afecta seguridad?
4. ¿Afecta producción, datos persistentes, credenciales o secretos?
5. ¿Propone más de un agente, un worker escritor, paralelo o equipo?
6. ¿Cumple el umbral de orquestación de `agents/README.md`?

La mutación elige exactamente un perfil base:

| Mutación | Perfil base |
| --- | --- |
| Ninguna; la tarea es análisis o auditoría | `audit` |
| Cambia código, configuración o implementación | `software` |
| No cambia código/configuración y no es auditoría | `solo` |

Después añade overlays ortogonales y combinables:

| Condición | Overlay | Efecto |
| --- | --- | --- |
| Riesgo o trabajo especializado de seguridad | `security` | Añade skills y gates de seguridad; no concede escritura |
| Producción, datos persistentes, credenciales o secretos | `production` | Añade aprobación, rollback y protección de estado; no concede escritura |
| El mecanismo supera principal + un subagente read-only | `orchestrated` | Habilita workers escritores, múltiples agentes, paralelo o equipo |

Por tanto, `audit + security` y `audit + production` son válidos y permanecen
read-only. `software` puede combinarse con los tres overlays. Si no se cumplen
los tres requisitos del umbral `orchestrated`, ejecuta secuencialmente.

## Resultado de clasificación

La clasificación es contexto interno o una sola línea breve, por ejemplo:

```text
software + security; standard; principal; gates: pruebas y validación especializada.
```

Persístela solo cuando la tarea abarque varias sesiones o lo exijan el usuario o
el perfil. Nunca escribas clasificación ni documentación durante `audit`.

Antes de ejecutar deben quedar resueltos, aunque no se publiquen como plantilla:
perfil base, overlays, contexto mínimo, mecanismo, nivel de coste, gates y
criterio observable de finalización. Carga solo las secciones seleccionadas y los
punteros necesarios; amplía el contexto únicamente con evidencia.

## Ejemplos

| Solicitud | Respuesta de clasificación |
| --- | --- |
| Corregir un typo en documentación | `solo; fast; principal; escritura documental acotada` |
| Corregir un typo o cambio mínimo en código | `software; fast; principal; pruebas proporcionales` |
| Auditar seguridad sin cambios | `audit + security; deep por riesgo; principal; read-only` |
| Analizar un incidente de producción | `audit + production; deep por riesgo; principal; read-only` |
| Implementar frontend y backend realmente independientes | `software + orchestrated; deep; paralelo solo si supera el umbral` |
