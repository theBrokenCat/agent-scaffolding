# Delegacion y coordinacion

La app es el lead: conserva decisiones, contratos compartidos, integracion y
verificacion final. Delega scopes, no responsabilidad.

## Roles genericos

Estos cuatro roles son opciones del lead, no etapas obligatorias. Tecnologia,
dominio, contexto y paths permitidos se describen en el brief:

| Rol | Responsabilidad | Alias por defecto | Escalada |
| --- | --- | --- | --- |
| `explorer` | localizar evidencia, dependencias, riesgos y opciones; read-only | `economy` | `balanced` si la busqueda es multiarchivo |
| `implementer` | cambiar solo los paths asignados y devolver verificaciones | `balanced` | `frontier` si se cumple cualquiera de los dos gates |
| `spec-reviewer` | comprobar requisitos, alcance y contratos antes de implementar; no implementar | `frontier` con effort `high` | `frontier` con effort `xhigh` en seam critico |
| `quality-reviewer` | revisar defectos, regresiones, mantenibilidad, tests y cumplimiento del contrato; no implementar | `frontier` | `critical` solo en auditoria final excepcional |

No crees roles `frontend`, `backend`, `security` o similares. Expresa esa
especialidad como dominio, skill y criterios del brief. El gate de seguridad de
[`policies/README.md`](../policies/README.md) y una skill con `domain: security`
cubren la especialidad de seguridad; no existe un quinto rol.

La arquitectura la conserva el lead. Cuando un seam critico merezca una segunda
opinion, lanza un `spec-reviewer` con brief de *design critic*: read-only, antes
de implementar, devuelve evidencia y objeciones ordenadas y no decide ni edita.
Sigue siendo el lead quien elige el diseno.

El trabajo de documentacion y extraccion no es un rol: es un brief `economy`
sobre `explorer` o `implementer`.

### Seleccion por necesidad

- El lead define el resultado y selecciona solo las responsabilidades que aportan
  valor. No hay que lanzar los cuatro roles para completar una tarea.
- En trabajo delegado, el flujo habitual es: lead define, `implementer` ejecuta,
  `quality-reviewer` revisa y lead integra. La ejecucion directa sigue siendo
  valida; se conserva la revision independiente exigida antes de integrar.
- Lanza `explorer` solo con una pregunta acotada cuya investigacion reduzca
  contexto o tiempo del lead. Si la evidencia ya esta disponible, no lo lances.
- Lanza `spec-reviewer` solo ante una pregunta sobre ambiguedad relevante,
  contratos compartidos o decisiones costosas de revertir. El brief identifica
  esa pregunta o riesgo; el rol no se activa por el mero tamano de una tarea.
- Cada lanzamiento debe indicar resultado esperado y criterio de cierre. Los
  gates de seguridad, produccion y publicacion conservan su autoridad actual.

## Modelo y effort

Los roles canonicos son **cuatro**. Cada ficha de [roles/](roles/) declara
alias, effort y escalada; `scripts/gen-agents` materializa los estados por host.
Un archivo generado es un estado materializado, no un rol nuevo. El nombre
incluye rol y estado; `explorer` conserva ademas el alias desnudo que sobrescribe
el built-in. Los nombres concretos se consultan en las capacidades del host o con
`scripts/gen-agents --host <host> --list`.

El mapping provisional y los gates de escalada viven solo en [ROUTER.md](../ROUTER.md).
El brief justifica la seleccion; una tarea larga necesita aceptacion y division
antes de atribuir su dificultad a la capacidad del modelo. Si no hay estado
compatible disponible, declara la limitacion; no inventes un alias.

## Mecanismos y limites

- `fast`: solo lead, sin delegacion.
- `standard`: lead y como maximo un worker activo; implementacion y revision
  independiente pueden sucederse sin exigir un equipo paralelo.
- `deep`: lead y el presupuesto de concurrencia completo.
- Presupuesto de concurrencia: **8 agentes simultaneos como maximo**, de los
  cuales **como maximo 3 writers**; los readers ocupan el resto
  (`readers <= 8 - writers`). El limite superior es el del host
  (`max_concurrent_threads_per_session = 8`), no una cifra aspiracional: si el
  host expone menos, manda el host.
- Un lote grande no es gratis. Usa el presupuesto solo mientras cada agente
  adicional tenga un scope real e independiente; por debajo de eso, secuencial.
- No existe delegacion anidada.
- Paralelo requiere al menos dos scopes independientes, escrituras disjuntas y
  ahorro neto tras coordinacion e integracion.
- Si el host no soporta paralelo o teams, usa secuencial, `cli-handoff` o
  `hybrid`; nunca simules la capacidad.

## Brief de lanzamiento

Antes de lanzar un worker, declara: objetivo observable; rol y dominio; incluido
y excluido; autoridad; paths de escritura exclusivos o read-only; SHA base;
dependencias compartidas; esfuerzo y alias, con el gate que justifica cualquier
escalada; verificacion; condicion de STOP.
Entrega punteros y extractos minimos, no el repositorio ni logs completos.

Un `implementer` trabaja en worktree o aislamiento equivalente desde el SHA
declarado. Dos writers nunca comparten paths, schemas, lockfiles, migrations,
generated ni snapshots. Si cambia la base, aparece solapamiento o trabajo ajeno,
el worker para y devuelve el conflicto; no integra por su cuenta.

## Orquestacion

Estas reglas son parte del contrato, no una skill aparte. El registro solo
apunta a esta seccion.

### Lote y espera

- **Spawnea todo el lote independiente antes de la primera espera.** Un worker
  lanzado despues de empezar a esperar serializa el lote y desperdicia el
  presupuesto de concurrencia.
- **Nunca forkees los turnos del padre cuando el alias importe.** Un
  `spawn_agent` con `fork_turns: "all"` hace que el subagente herede modelo y
  effort de la sesion padre e ignore los del agente, sin error ni aviso, y la
  herramienta no admite override explicito de modelo o effort al forkear. Spawnea
  sin fork; si el fork es imprescindible, registra que ese despacho corrio en el
  par del padre y no en el del alias.
- **La escalada se despacha por nombre, no por override.** Cuando `agent_type`
  nombra un agente custom, la definicion del archivo gana a `model` y
  `reasoning_effort` de `spawn_agent`: el override se acepta sin error y se
  ignora. Por eso cada rol se materializa en dos archivos, uno por estado, y
  escalar significa despachar `<rol>-<estado escalado>`.
- Modelo observado distinto del alias es **FALLO**, no una variante aceptable.
- `wait_agent` **no** es un wait-for-all atomico: despierta por evento o por
  timeout, y puede despertar sin que el conjunto esperado haya terminado.
- Bucle correcto: espera con bounds **largos**, procesa los eventos recibidos,
  retira del conjunto esperado los agentes terminales y vuelve a esperar. No
  re-emitas esperas cortas ni generes razonamiento nuevo cuando el estado no ha
  cambiado; un despertar sin cambio de estado se responde volviendo a esperar.
- El presupuesto de espera es tiempo, no numero de despertares. Agotarlo activa
  el SLA de reviewer o un STOP, no una ronda de esperas mas cortas.

### Hallazgos y correcciones

- Agrupa los hallazgos contra un **snapshot congelado** (SHA declarado) y emite
  **un solo lote de correccion** al owner de esos paths. Nunca lances un agente
  nuevo por microhallazgo.
- No re-corras gates amplios —suite completa, revision integrada, auditoria—
  despues de cada microfix. Se ejecutan una vez, sobre el snapshot estable.

### Excepciones

1. **STOP-early.** Si un hallazgo `Blocking` invalida el snapshot, congela el
   lote; pero cierra antes el inventario causal, para no parchear un sintoma y
   descubrir el resto en la siguiente ronda.
2. **Correcciones en paralelo.** Solo si son causalmente independientes y sobre
   paths disjuntos; en cualquier otro caso, secuencial sobre el mismo owner.
3. **Reset del contrato.** A la **segunda** reapertura del mismo seam o de la
   misma familia de invariantes, para el parcheo y rehaz el contrato. Una tercera
   ronda de parches sobre el mismo seam es una senal de diseno, no de ejecucion.
4. **SLA de reviewer.** Si un reviewer no devuelve dentro de su bound, sustituyelo
   o declaralo bloqueado con evidencia. No esperes indefinidamente ni des por
   aprobado lo que nadie reviso.
5. **Revision final integrada.** Mantenla aunque cada reviewer estrecho haya
   pasado: dos revisiones estrechas dejan sin cubrir la interaccion entre sus
   dominios.

## Trabajo multisesion

Para cada objetivo que requiera varias sesiones, usa su issue o documento de
trabajo existente como registro unico. Si no existe, crea un registro breve donde
el proyecto ya gestione tareas. No instales un segundo backlog ni archivos
obligatorios del scaffolding. El lead es responsable de mantenerlo; los workers
aportan evidencia mediante el retorno comun.

Conserva solo lo necesario para continuar:

| Dato | Contenido |
| --- | --- |
| Resultado | Objetivo, scope y criterios de aceptacion observables. |
| Estado y dependencias | Que esta pendiente, bloqueado, en revision o aceptado; IDs de dependencias y decisiones abiertas. |
| Propiedad | Responsable, paths asignados y autoridad concedida. |
| Checkout | Worktree/rama, SHA base y actual; cambios sin commit que deben preservarse. |
| Evidencia | Comandos y resultados, SHA revisado, hallazgos pendientes y enlaces a artefactos. |
| Siguiente accion | Paso o comando concreto, bloqueo y condicion de STOP. |

Al retomar, contrasta el registro con Git y los artefactos actuales. No reutilices
un pass de otro SHA ni declares terminada una dependencia porque un worker diga
`completed`. Si hay drift, evalua el impacto y revalida antes de continuar;
no sobrescribas trabajo ajeno ni ejecutes dependencias bloqueadas.

Actualiza el registro al cambiar estado, cerrar un checkpoint o terminar la
sesion, no por cada herramienta. Deja las decisiones sin confirmar marcadas como
pendientes. Un objetivo se acepta solo cuando sus criterios y reviews requeridas
se han verificado; implementacion, integracion y despliegue son estados distintos.
El relevo no autoriza acciones nuevas ni obliga a publicar trabajo parcial.

## Envelope de retorno

Este es el unico formato de retorno de los cuatro roles. El generador incorpora
esta seccion completa en cada definicion; las fichas no mantienen formatos
alternativos. Devuelve exactamente estas claves, sin campos adicionales:

```yaml
status: <completed|blocked|partial>
verdict: <pass|changes-requested|not-assessed|not-applicable>
summary: <resultado breve>
changes_or_findings: <paths y cambios, o hallazgos>
verification: <comandos/evidencia y resultado>
risks: <riesgo residual o none>
references: <paths, lineas, commits o enlaces pertinentes>
next_action: <accion concreta o none>
```

`status` describe la ejecucion del scope asignado; `verdict` describe la decision
de una revision. Para `explorer` e `implementer`, usa `not-applicable`. Para los
reviewers:

- Revision terminada: `completed` y `pass` o `changes-requested`. Completar una
  revision con hallazgos no aprueba el trabajo; `changes_or_findings` incluye
  severidad, ubicacion, impacto y evidencia, o las lagunas de la especificacion.
- Revision parcial, bloqueada o sin evidencia requerida: `partial` o `blocked`
  y `not-assessed`. Nunca se interpreta como aprobacion.

Para un implementer, `completed` exige cambio y verificacion terminados. Para un
explorer, exige respuesta sustentada; si falta evidencia para responder, usa
`partial` o `blocked`. Expresa lagunas, supuestos y riesgos en los campos comunes.
Solo una revision terminada con `verdict: pass` satisface el gate correspondiente;
no sustituye los demas checks ni concede autoridad de merge o publicacion.

No adjuntes logs completos. Incluye el fragmento necesario para explicar un
fallo y la siguiente accion concreta. `partial` nunca equivale a exito.

## Integracion

El lead inspecciona cada retorno y diff, resuelve integracion sobre su propiedad
y repite las verificaciones aplicables. Despues usa commits, checkpoint pushes y
draft PR conforme al ciclo global sin reconfirmar cada accion; el merge conserva
su gate explicito. Cierra workers y limpia recursos temporales unicamente cuando
todo trabajo este preservado. Los limites de loops y acciones Git viven en
[`policies/README.md`](../policies/README.md).
