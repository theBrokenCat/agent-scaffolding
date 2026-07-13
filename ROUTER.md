# Router app-first

El router elige el mecanismo minimo que puede completar la tarea. No concede
permisos y no asigna herramientas a roles fijos. `app-direct` es el default.

## Orden de decision

Clasifica con esta precedencia:

1. instruccion explicita del usuario;
2. autoridad y restricciones aplicables;
3. mutacion y superficie de escritura;
4. riesgo, especialmente seguridad y produccion;
5. coste del contexto que debe conservarse;
6. independencia real entre scopes;
7. capacidades disponibles en el host.

Si una opcion no existe en el host, degrada a la siguiente viable y dilo. No
simules teams, workers, seleccion de modelo ni medicion de coste.

## Mecanismos

| Mecanismo | Uso |
| --- | --- |
| `app-direct` | Default: la app investiga, implementa, revisa e integra. |
| `app-delegated` | La app conserva decisiones e integracion; un worker resuelve un scope acotado. |
| `app-parallel` | La app integra scopes independientes; writers usan paths y worktrees disjuntos. |
| `cli-handoff` | El usuario pide CLI o la app carece de una capacidad necesaria; se entrega un brief autocontenido. |
| `hybrid` | La app gobierna decisiones e integracion y usa CLI para una parte concreta. |

Elige delegacion solo si reduce contexto o tiempo neto. Elige paralelo solo para
dos o mas scopes independientes, con propiedad disjunta y coste de integracion
menor que el ahorro. Sigue los limites de [`agents/README.md`](agents/README.md).

## Preflight selectivo

Para trabajo sustancial usa exactamente:

```text
Recomiendo: <app-direct|app-delegated|app-parallel|cli-handoff|hybrid>
Motivo: <una frase>
La app conservara: <decisiones e integracion>
Delegare: <scope o nada>
Confirmacion necesaria: <si/no>
```

No preguntes para `fast`. En `standard` o `deep`, escrituras amplias, equipos,
seguridad, produccion o relevo, pregunta solo si el mecanismo cambia coste,
autoridad, paths de escritura o destino. Una preferencia explicita del usuario
ya cuenta como decision salvo conflicto superior.

## Esfuerzo, modelo y mapping local

El esfuerzo es `fast`, `standard` o `deep`. `fast` cubre una pasada acotada;
`standard` es el nivel sustancial normal; `deep` exige riesgo o complejidad
justificados. Esfuerzo no significa autoridad.

Los aliases portables son `economy`, `balanced` y `frontier`. El mapping inicial
local es:

| Alias | Mapping local inicial | Uso |
| --- | --- | --- |
| `economy` | Luna | tarea acotada y baja ambiguedad |
| `balanced` | Terra | implementacion o analisis normal |
| `frontier` | Sol | alto riesgo, contexto complejo o revision exigente |

Luna, Terra y Sol no forman parte del contrato portable. Cada host puede mapear
los aliases a capacidades equivalentes. Si no permite seleccionar modelo, usa
el disponible, conserva el alias como intencion y no afirmes que aplicaste el
mapping.

## Tabla de decisiones

| Caso | Mecanismo | Pregunta | Esfuerzo / alias | Contexto que conserva la app | Gate |
| --- | --- | --- | --- | --- | --- |
| Typo | `app-direct` | no | `fast / economy` | archivo y diff | diff/check |
| Feature acotada | `app-direct` | no, salvo escritura amplia | `standard / balanced` | contrato, codigo y pruebas | baseline y pruebas |
| Investigacion grande | `app-delegated` | si si cambia coste | `standard / balanced` | pregunta, evidencia e integracion | referencias verificadas |
| Frontend/backend disjuntos | `app-parallel` | si | `deep / balanced` | contrato compartido e integracion | paths/worktrees y suite final |
| Security diff | `app-delegated` o `app-direct` | si si cambia coste o autoridad | `deep / frontier` | threat context y veredicto | skill y validacion especializada |
| Hotfix de produccion | `app-direct` o `hybrid` | si | `deep / frontier` | decisiones, rollback e integracion | aprobacion, rollback y checks |
| Usuario pide CLI sin selector de modelo | `cli-handoff` | no | nivel aplicable / alias como intencion | alcance y aceptacion del retorno | declarar fallback y verificar |

Los perfiles de coste y riesgo estan en
[`profiles/README.md`](profiles/README.md); roles y envelopes en
[`agents/README.md`](agents/README.md).
