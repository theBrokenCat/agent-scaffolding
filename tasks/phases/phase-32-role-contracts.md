# Issue 32: contratos coherentes y roles por necesidad

Base: `2bf09b04ab4d2685636270f501acd9b47b14ba80` (`origin/main`).
Autorización: puntos 1 y 2 del análisis; implementación, feature push y draft PR.

## Diseño aprobado y decisiones de implementación

- Conservar los cuatro roles y todos sus estados/modelos. El lead selecciona
  responsabilidades por necesidad; exploración y spec review necesitan una
  pregunta o riesgo concreto. En trabajo delegado: definir, implementar, revisar,
  integrar. La ejecución directa sigue siendo válida; los gates independientes
  de integración y seguridad se mantienen.
- Un único envelope en `agents/README.md`. Separar estado de ejecución
  (`completed|partial|blocked`) del veredicto de revisión
  (`pass|changes-requested|not-assessed|not-applicable`). Un review completado con
  hallazgos no significa aprobación. Las fichas usan el formato común sin duplicarlo.
- El generador incorpora el cuerpo de cada ficha y el contrato de retorno;
  conserva el routing materializado y las restricciones de herramientas.
  Las definiciones deben ser utilizables desde otro cwd sin buscar el scaffolding.
- CI publica `reviewer-disabled` cuando la variable `AGENT_REVIEWER_ENABLED`
  no es `true`. Solo publica `reviewer` si se activa explícitamente; entonces
  la falta de credencial/harness o un fallo real impide un resultado verde.
  No se activa el reviewer, no se configura GitHub y no se crea un proveedor LLM.

## Plan y evidencia

- [x] Issue, worktree aislado y baseline: siete suites pasan; Broken pipe preexistente.
- [x] RED: generar desde otro cwd; comprobar cuerpo completo, envelope común,
  TOML válido y ausencia de búsquedas relativas. Probar estados desactivado,
  mal configurado y revisión ejecutada en CI sin credenciales reales ni red.
- [x] GREEN: actualizar generador, fichas, contrato, selección y workflow/docs.
- [x] Verificar regresiones, suite completa, sintaxis shell y diff.
- [x] Congelar commit, revisión independiente, resolver hallazgos en lote.
- [x] Push, draft PR y CI; registrar SHA/evidencia final.

Paths: `agents/`, `scripts/gen-agents`, `tests/gen_agents_test.sh`,
`tests/ci_reviewer_test.sh`, `tests/orchestration_test.sh`, `AGENTS.md`,
`ROUTER.md`, `policies/README.md`, `.github/workflows/ci.yml`, `.github/README.md`,
`README.md`, `tests/runtime-parity.md`, `tasks/todo.md` y este plan.

Excluido: selección de modelos/escaladas, pilotos/arnés, objetivos multisesión,
permisos efectivos, instalación global, merge, despliegue y trabajo preexistente.
STOP: cambio de autoridad, scope, baseline o presupuesto de revisión agotado.

Regresiones observadas antes del fix: cuerpo de ficha ausente; check reviewer
publicado estando desactivado; Codex generaba sin el contrato común cuando faltaba
el fichero. Las tres regresiones pasan después. La prueba adicional confirma que
backslashes y comillas triples sobreviven a la decodificación TOML.

## Cierre de implementación

Implementación: `bf72039b84f266992cacb593763f724624c805dd`.
Ocho suites locales verdes; sintaxis shell, YAML y diff-check correctos.
Revisión independiente `quality-reviewer-frontier`, tarea
`/root/review_role_contracts`: pass, sin hallazgos. El revisor repitió generación,
estados de CI, contrato de orquestación, sintaxis y diff-check sobre ese SHA.

Draft PR: https://github.com/theBrokenCat/agent-scaffolding/pull/33
CI de implementación: run `33933077755`, `tests` SUCCESS y `reviewer-disabled`
SUCCESS. Este último acredita desactivación y no sustituye la revisión anterior.
La PR mantiene el estado/checks actualizados para cualquier commit documental
posterior. Los avisos Broken pipe son anteriores y no impiden los checks.

Instalación global, activación runtime y merge pendientes de autorización;
no se cambió el checkout canónico ni la configuración de los hosts.
