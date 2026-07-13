# Delegacion y coordinacion

La app es el lead: conserva decisiones, contratos compartidos, integracion y
verificacion final. Delega scopes, no responsabilidad.

## Roles genericos

Usa solo estos roles; tecnologia y dominio se describen en el brief:

| Rol | Responsabilidad |
| --- | --- |
| `explorer` | localizar evidencia, dependencias, riesgos y opciones; read-only |
| `implementer` | cambiar solo los paths asignados y devolver verificaciones |
| `spec-reviewer` | comprobar requisitos, alcance y contratos; no implementar |
| `quality-reviewer` | revisar defectos, regresiones, mantenibilidad y tests; no implementar |

No crees roles `frontend`, `backend`, `security` o similares. Expresa esa
especialidad como dominio, skill y criterios del brief.

## Mecanismos y limites

- `fast`: solo lead, sin delegacion.
- `standard`: lead y como maximo un worker acotado.
- `deep`: lead y como maximo tres workers.
- No existe delegacion anidada.
- Paralelo requiere al menos dos scopes independientes, escrituras disjuntas y
  ahorro neto tras coordinacion e integracion.
- Si el host no soporta paralelo o teams, usa secuencial, `cli-handoff` o
  `hybrid`; nunca simules la capacidad.

## Brief de lanzamiento

Antes de lanzar un worker, declara: objetivo observable; rol y dominio; incluido
y excluido; autoridad; paths de escritura exclusivos o read-only; SHA base;
dependencias compartidas; esfuerzo y alias; verificacion; condicion de STOP.
Entrega punteros y extractos minimos, no el repositorio ni logs completos.

Un `implementer` trabaja en worktree o aislamiento equivalente desde el SHA
declarado. Dos writers nunca comparten paths, schemas, lockfiles, migrations,
generated ni snapshots. Si cambia la base, aparece solapamiento o trabajo ajeno,
el worker para y devuelve el conflicto; no integra por su cuenta.

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
