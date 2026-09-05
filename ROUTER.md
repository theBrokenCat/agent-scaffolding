# Router app-first

Elige el mecanismo minimo que complete el objetivo. `app-direct` es el default.
El router selecciona capacidad y proceso; la autoridad procede de [AGENTS.md](AGENTS.md).

## Orden de decision

1. Respeta la peticion, autoridad y restricciones aplicables.
2. Define resultado y aceptacion observable antes de implementar. Si faltan,
   el lead los concreta y usa spec review solo ante una pregunta o riesgo relevante.
3. Identifica dependencias, ownership y riesgo. Divide el trabajo cuando cada
   parte pueda verificarse sin perder las invariantes compartidas.
4. Elige mecanismo, esfuerzo y estado con las capacidades reales del host.
   Delega solo si reduce contexto o tiempo neto; paraleliza scopes independientes.

Un repositorio grande no obliga a un equipo ni a un modelo mayor. Si una capacidad
falta, declara la degradacion y usa una opcion viable; no simules soporte.

## Mecanismos

| Mecanismo | Uso |
| --- | --- |
| `app-direct` | El lead investiga, implementa e integra. |
| `app-delegated` | Un worker resuelve un scope acotado; el lead conserva decisiones e integracion. |
| `app-parallel` | Scopes independientes con ownership/aislamiento disjunto y ahorro neto. |
| `cli-handoff` | Peticion de CLI o capacidad necesaria ausente en la app; brief autocontenido. |
| `hybrid` | El lead usa CLI para una parte concreta y conserva el gobierno del trabajo. |

Los cuatro roles son opciones, no una cadena obligatoria. Su seleccion y los
limites reales viven en [agents/README.md](agents/README.md). La ejecucion directa
conserva los gates de revision independiente aplicables.

## Preflight selectivo

Usa el formato y la autoridad de [AGENTS.md](AGENTS.md#2-inicio-y-preflight).
`fast` no pregunta. Para el resto, solo confirma si cambia coste, autoridad,
superficie de escritura o destino y esa decision no esta ya autorizada.

## Esfuerzo, modelo y mapping local

| Esfuerzo | Uso | Proceso |
| --- | --- | --- |
| `fast` | Cambio pequeno o pregunta acotada | Una pasada, lead sin delegacion. |
| `standard` | Feature o diagnostico normal | Directo; un worker activo si aporta valor. |
| `deep` | Integracion compleja, riesgo o revision exigente | Equipo solo con independencia real; no es un mandato de paralelismo. |

Un alias selecciona dos cosas **del subagente**: su modelo y su reasoning effort.
No concede autoridad ni convierte el nivel de esfuerzo en un modelo del lead.
El mapping real vive en `~/.config/agent-scaffolding/model-map.yaml`, por host;
`scripts/gen-agents` resuelve las fichas y detiene un host sin mapping propio.
Ver [settings/schemas/model-map.example.yaml](settings/schemas/model-map.example.yaml).

La referencia de configuracion Codex se conserva como politica **provisional**:

| Alias | Referencia | Uso |
| --- | --- | --- |
| `economy` | Luna `high` | Trabajo mecanico, docs o exploracion acotada. |
| `balanced` | Luna `xhigh` | Exploracion multiarchivo o implementacion especificada. |
| `frontier` | Sol `xhigh` | Gates de capacidad y reviewers; una ficha puede declarar otro effort. |
| `critical` | Sol `max` | Auditoria final excepcional, justificada caso a caso. |

Estas elecciones no demuestran superioridad ni ahorro frente a otros modelos.
Terra sigue disponible como escalon diagnostico, sin cambiar los defaults
instalados. No se ha demostrado que este dominada en todos los trabajos: un
cambio de mapping requiere evidencia comparable y autoridad sobre su coste.
Los hosts sin selector registran el fallback; una intencion no prueba el modelo
realmente usado. Los resultados historicos de pilotos no son reglas operativas.

### Gates de escalada a la curva Sol

Para un implementer, escala a `frontier` con uno de estos gates justificado en
el brief. La regla es semantica: los paths son senal, no decision.

1. **Que toca (seam critico).** Contratos compartidos o APIs publicas; schema y
   migraciones; concurrencia; ciclo de vida durable, recovery e idempotencia;
   seguridad, auth y secretos; dinero/cuotas; efectos irreversibles; lockfiles,
   generated y snapshots. Mantiene sus invariantes y ownership explicitos.
2. **Razonamiento inseparable.** Un objetivo ya especificado necesita mantener
   decisiones o invariantes interdependientes que no pueden dividirse en tareas
   verificables independientes. El lead identifica cuales y por que dividirlas
   perderia el contrato; la duracion por si sola no basta.

Tener varios pasos, varios archivos o carecer de aceptacion no activa el segundo
gate. Primero concreta la aceptacion y divide lo separable. Si no puede definirse
un resultado verificable, no lances implementers: devuelve la decision pendiente.
Sin gate, usa el default de la ficha. Exploracion y reviewers mantienen sus
estados propios. No cambies de modelo para reiniciar un loop agotado; los
presupuestos estan en [policies/README.md](policies/README.md#equipos-orquestacion-y-loops).
