# Delegacion y coordinacion

La app es el lead: conserva decisiones, contratos compartidos, integracion y
verificacion final. Delega scopes, no responsabilidad.

## Roles genericos

Usa solo estos roles; tecnologia y dominio se describen en el brief:

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

## Modelo y effort

El alias fija modelo y reasoning effort del subagente. La tabla de curvas y los
dos gates de escalada a Sol —**que toca** (seam critico) y **cuanto dura**
(horizonte largo o sin criterios de aceptacion objetivos)— viven en
[`ROUTER.md`](../ROUTER.md). Cada ficha de [`roles/`](roles/) declara en su
frontmatter el alias, el effort, el alias escalado y el disparador exacto de la
escalada; esa ficha es la fuente canonica y `scripts/gen-agents` la materializa
por host.

Escala por evidencia, no por prudencia: un solo gate basta, y ninguno se cumple
por defecto. Terra nunca es el default de un rol; solo se usa como escalon
diagnostico puntual para separar un fallo de capacidad de un fallo del brief.

## Mecanismos y limites

- `fast`: solo lead, sin delegacion.
- `standard`: lead y como maximo un worker acotado.
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

## Envelope de retorno

Todo worker devuelve exactamente estas claves, sin campos adicionales:

```yaml
status: <completed|blocked|partial>
summary: <resultado breve>
changes_or_findings: <paths y cambios, o hallazgos>
verification: <comandos/evidencia y resultado>
risks: <riesgo residual o none>
references: <paths, lineas, commits o enlaces pertinentes>
next_action: <accion concreta o none>
```

No adjuntes logs completos por defecto. Incluye solo el fragmento necesario para
explicar un fallo. `completed` exige que el scope este cerrado y verificado;
`partial` no equivale a exito.

## Integracion

El lead inspecciona cada retorno y diff, resuelve integracion sobre su propiedad
y repite las verificaciones aplicables. Despues usa commits, checkpoint pushes y
draft PR conforme al ciclo global sin reconfirmar cada accion; el merge conserva
su gate explicito. Cierra workers y limpia recursos temporales unicamente cuando
todo trabajo este preservado. Los limites de loops y acciones Git viven en
[`policies/README.md`](../policies/README.md).
