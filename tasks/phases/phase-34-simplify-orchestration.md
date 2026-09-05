# Issue 34: simplificar gobierno y continuidad

Base: `bf5bca0433ec6e6f97e130b9699f89ab98f8845b` (PR #33 integrada).
El usuario autoriza eliminar exceso y añadir lo necesario para proyectos grandes.

## Contrato del cambio

- AGENTS conserva autoridad, contexto, Git y verificación; ROUTER decide esfuerzo
  y capacidad; agents/README posee roles, concurrencia, orquestación y retorno.
  policies conserva gates especializados y presupuestos de loops. profiles queda
  como enlace compatible, sin tablas/reglas duplicadas.
- Modelos actuales, nombres de estados, permisos y límites siguen iguales.
  La selección es provisional: faltan comparaciones válidas para afirmaciones de
  dominancia. Antes de implementar se hacen observables los criterios; tener
  varios pasos no fuerza una escalada. Escalar por frontera crítica o razonamiento
  inseparable justificado, sin usar la escalada para reiniciar un loop agotado.
- Un objetivo multisesión usa su issue o documento existente. Se registra
  aceptación, dependencias, autoridad/owner, checkout/SHA, evidencia y próximo
  paso; el lead actualiza al cambiar el estado y verifica al reanudar.
- Corregir Broken pipe por lectores awk que cierran antes de consumir role_states;
  probar render real sin ocultar stderr. No añadir dependencias ni un gestor nuevo.
- Mantener documentos de pilotos como historia, marcando que no gobiernan routing
  ni acreditan ahorro. No borrar evidencia ni el trabajo ajeno de otros worktrees.

## Ejecución

- [x] Issue y worktree aislado desde origin/main; medir texto de gobierno (6542 palabras en seis ficheros).
- [x] Baseline: ocho suites verdes; Broken pipe reproducido.
- [x] RED/GREEN del generador; actualizar checks que exigían duplicación de prosa.
- [x] Simplificar instrucciones y añadir protocolo de continuidad en un solo lugar.
- [x] Verificar enlaces, invariantes, modelos/estados intactos, suite completa y diff.
- [ ] Review independiente, draft PR, CI y cierre con evidencia.

Fuentes: AGENTS.md, ROUTER.md, profiles/README.md, policies/README.md,
agents/README.md, agents/roles/implementer.md, templates/README.md, README.md,
docs/pilots/2026-09-02-phase-2-model-routing.md, scripts/gen-agents,
tests/contract_test.sh, tests/orchestration_test.sh, tests/gen_agents_test.sh,
settings/schemas/model-map.example.yaml (descripcion de uso, sin cambio de mapping),
tasks/todo.md y este registro. Instalación, pilotos reales, merge y deploy fuera
del alcance. STOP por cambio de autoridad, ownership o límite agotado.

Comprobaciones de política para review: tarea mecánica con varios pasos no escala
por duración; aceptación ausente vuelve al lead; cambio de esquema conserva el
gate crítico; relevo con SHA distinto debe revalidar evidencia. Son escenarios
de revisión del contrato, no ejecuciones de modelos ni resultados de un piloto.

Verificacion local: ocho suites verdes, sin avisos internos Broken pipe en el
generador/instalador; sh -n y diff-check pasan. Texto de gobierno: 6542 -> 4506
palabras (31.1% menos). Es volumen de instrucciones, no ahorro medido de tokens,
tiempo o dinero. Modelos, efforts, estados y autoridad de roles conservados.
