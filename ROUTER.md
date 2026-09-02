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

Los aliases portables son `economy`, `balanced`, `frontier` y `critical`. Un
alias selecciona dos cosas **del subagente**: su modelo y su reasoning effort.
No concede autoridad, no elige rol y no sustituye al nivel de esfuerzo, que
limita el proceso del lead. Un rol puede fijar un effort distinto al del alias
sobre la misma curva; esa excepcion se declara en su ficha de
[`agents/roles/`](agents/roles/).

El mapeo concreto no se versiona: vive en el model map local
(`~/.config/agent-scaffolding/model-map.yaml`) y se materializa por host con
`scripts/gen-agents`. El alias es lo portable; el id de modelo **no lo es**, asi
que el mapa resuelve un id por host y un host sin id para un alias detiene el
generador en vez de tomar prestado el de otro. [`settings/schemas/model-map.example.yaml`](settings/schemas/model-map.example.yaml)
documenta la forma del archivo con nombres en clave, no la seleccion real.

Solo hay dos curvas por defecto:

| Alias | Curva y effort | Uso |
| --- | --- | --- |
| `economy` | Luna `high` | docs, extraccion, exploracion acotada, fixes mecanicos |
| `balanced` | Luna `xhigh` | exploracion multiarchivo, implementacion con contrato congelado |
| `frontier` | Sol `xhigh` | seam critico, horizonte largo, reviewers |
| `critical` | Sol `max` | solo auditoria final excepcional |

Terra queda fuera de las curvas por defecto porque esta dominada en Pareto en
todos sus niveles de effort. Solo se usa como escalon diagnostico puntual, para
distinguir un fallo de capacidad del modelo de un fallo del brief, y nunca es el
default de un rol.

### Gates de escalada a la curva Sol

Escala a `frontier` cuando se cumpla **cualquiera** de estos dos gates. La regla
es semantica: los paths son senal, no decision.

1. **Que toca (seam critico).** Contratos compartidos o APIs publicas; schema y
   migraciones; concurrencia y orden de ejecucion; estado durable y su ciclo de
   vida, incluidos recovery e idempotencia; seguridad, auth y secretos; dinero y
   cuotas; efectos irreversibles; lockfiles, generated y snapshots.
2. **Cuanto dura (horizonte largo).** Trabajo multi-paso, de horizonte largo o
   sin criterios de aceptacion objetivos, aunque no toque nada critico.

Un solo gate basta. Si no se cumple ninguno, no subas de curva: `balanced` es el
default de implementacion y `economy` el de trabajo mecanico o acotado.

## Tabla de decisiones

| Caso | Mecanismo | Pregunta | Esfuerzo / alias | Contexto que conserva la app | Gate |
| --- | --- | --- | --- | --- | --- |
| Typo | `app-direct` | no | `fast / economy` | archivo y diff | diff/check |
| Documentacion o extraccion acotada | `app-direct` o `app-delegated` | no | `fast / economy` | contrato y fuentes | diff y referencias |
| Feature acotada | `app-direct` | no, salvo escritura amplia | `standard / balanced` | contrato, codigo y pruebas | baseline y pruebas |
| Investigacion grande | `app-delegated` | si si cambia coste | `standard / balanced` | pregunta, evidencia e integracion | referencias verificadas |
| Frontend/backend disjuntos | `app-parallel` | si | `deep / balanced` | contrato compartido e integracion | paths/worktrees y suite final |
| Seam critico o horizonte largo | `app-direct` o `app-delegated` | si si cambia coste o autoridad | `deep / frontier` | contrato, invariantes e integracion | gate de escalada y suite final |
| Security diff | `app-delegated` o `app-direct` | si si cambia coste o autoridad | `deep / frontier` | threat context y veredicto | skill y validacion especializada |
| Hotfix de produccion | `app-direct` o `hybrid` | si | `deep / frontier` | decisiones, rollback e integracion | aprobacion, rollback y checks |
| Auditoria final excepcional | `app-delegated` | si | `deep / critical` | veredicto y evidencia | revision integrada sobre snapshot estable |
| Usuario pide CLI sin selector de modelo | `cli-handoff` | no | nivel aplicable / alias como intencion | alcance y aceptacion del retorno | declarar fallback y verificar |

Los perfiles de coste y riesgo estan en
[`profiles/README.md`](profiles/README.md); roles, orquestacion y envelopes en
[`agents/README.md`](agents/README.md).
