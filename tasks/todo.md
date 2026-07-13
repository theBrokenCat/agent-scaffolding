# Agent Scaffolding v0.1 - Plan

**Goal:** Crear un scaffolding personal mínimo y compartido por Codex, Claude y Gemini.
**Stack:** Markdown, Git, GitHub CLI y shell POSIX solo si el piloto justifica scripts.

---

## Fase 1 - Contrato común y adaptadores

- [x] Crear `README.md` y explicar instalación, alcance y mantenimiento.
- [x] Crear `AGENTS.md` como fuente canónica.
- [x] Crear adaptadores mínimos `CLAUDE.md` y `GEMINI.md`.
- [x] Verificar que no existan reglas comunes duplicadas.
- [x] Commit: `docs: add shared agent contract`

## Fase 2 - Router, perfiles y delegación

- [x] Crear `ROUTER.md` con precedencia y tabla de decisión.
- [x] Crear `profiles/README.md` con seis perfiles y gates.
- [x] Crear `agents/README.md` con escalera de delegación y protocolo de equipos.
- [x] Validar seis escenarios de enrutamiento manualmente.
- [x] Commit: `docs: define workflow routing and delegation`

## Fase 3 - Políticas operativas

- [x] Crear `policies/README.md`.
- [x] Definir Git/GitHub, tokens, MCP, Outline, seguridad y documentación.
- [x] Acotar bucles, autoridad automática y condiciones de parada.
- [x] Comprobar que ninguna política contradiga los adaptadores.
- [x] Commit: `docs: add operational policies`

## Fase 4 - Contrato de proyecto y pull requests

- [x] Crear `templates/README.md` con estructura mínima y extensiones bajo demanda.
- [x] Crear `.github/README.md` con reglas del repositorio.
- [x] Crear `.github/pull_request_template.md`.
- [x] Verificar que el template no genere directorios opcionales.
- [x] Commit: `docs: add project and pull request contracts`

## Fase 5 - Validación, GitHub y piloto

- [x] Revisar enlaces, imports, nombres y límites de contexto.
- [x] Ejecutar escenarios de presión y registrar resultados.
- [x] Crear repositorio privado de GitHub y publicar la rama.
- [ ] Abrir PR de v0.1 y verificar su flujo completo.
- [x] Seleccionar un proyecto piloto sin modificarlo todavía.
- [x] Commit: `test: validate scaffolding workflow`

---

## Review

### Hechos observados

- Validación mecánica: enlaces Markdown relativos OK; `CLAUDE.md` y `GEMINI.md`
  importan `@AGENTS.md` en la primera línea; no hay directorios vacíos.
  `git diff --check` queda como verificación final de esta documentación.
- Contexto: `AGENTS.md` tiene 1257 palabras y el contrato completo 6711. La
  carga selectiva del router es obligatoria. No se afirma que el host respete el
  presupuesto cuando carga plugins o skills globales.
- Casos esperados: typo en docs -> `solo/fast/principal`; typo en código ->
  `software/fast/principal`; `/improve` read-only ->
  `audit/standard/principal`; security review read-only ->
  `audit+security/deep/principal`; hotfix de producción con datos ->
  `software+production/deep/principal`, con aprobación y rollback; frontend y
  backend independientes con umbral probado ->
  `software+orchestrated/deep/2 writers` en worktrees disjuntos.
- Evidencia runtime reproducible, sin secretos ni logs extensos:

  ```sh
  codex exec --ephemeral --sandbox read-only --color never "Valida el router de este repositorio sin editar nada. Clasifica exactamente estos dos casos conforme a AGENTS.md, ROUTER.md, profiles/README.md y agents/README.md: (1) corregir un typo en código; (2) auditoría /improve read-only de todo el repo. Devuelve solo dos líneas: caso | perfil+overlays | coste | mecanismo | gate principal. No expliques."
  claude -p --no-session-persistence --permission-mode plan --tools "" --effort low "Valida el router de este repositorio sin editar nada. Clasifica exactamente estos dos casos conforme a AGENTS.md, ROUTER.md, profiles/README.md y agents/README.md: (1) revisión de seguridad read-only; (2) hotfix de producción que cambia código y toca datos persistentes. Devuelve solo dos líneas: caso | perfil+overlays | coste | mecanismo | gate principal. No expliques."
  gemini --approval-mode plan --output-format text -p "Valida el router de este repositorio sin editar nada. Clasifica exactamente estos dos casos conforme a AGENTS.md, ROUTER.md, profiles/README.md y agents/README.md: (1) corregir un typo en documentación; (2) implementar frontend y backend independientes con escrituras disjuntas y ahorro neto de coordinación demostrado. Devuelve solo dos líneas: caso | perfil+overlays | coste | mecanismo | gate principal. No expliques."
  ```

  La primera invocación de Codex dentro del sandbox terminó con exit `1` por
  `EPERM` al iniciar el app-server; la repetición autorizada en el host mantuvo
  sandbox read-only. Codex CLI 0.144.1, sesión
  `019f5b6b-232b-75e0-921d-56b49f97fd40`, terminó con exit `0` y clasificó las
  dos líneas como `software/fast/principal` y
  `audit/standard/principal`, aunque también reportó errores de skills/MCP.
  Consumió 39.307 tokens: es un overrun frente al cap agregado `fast` de 12k y
  demuestra que el host actual no cumple `fast`, no solo un riesgo genérico.
  Claude Code 2.1.205 terminó con exit `1` por `401 invalid auth`; su validación
  está bloqueada. Gemini CLI 0.46.0 falló tras un cliente free-tier no soportado
  y una escritura de credenciales restringida; su validación también está
  bloqueada y no se obtuvo una salida de éxito. No se reintentó ni se declara
  éxito cruzado.
- GitHub: `theBrokenCat/agent-scaffolding` es privado, `main` está publicada,
  el ruleset `Protect main` está activo con
  `required_review_thread_resolution=true`. Se verificaron mediante la API el
  requisito de PR, el bloqueo de deletion, el bloqueo de non-fast-forward y la
  resolución obligatoria de conversaciones. La draft PR #1 está abierta y
  mergeable. No hay CI justificada.
- Piloto: `/Users/arturo/Proyectos/personal-life`, limpio al seleccionar, de
  riesgo moderado, Python con tests y superficies de API, persistencia,
  Telegram, Outline y operaciones. No se modifica en esta fase.

### Desviaciones y riesgo residual

La presión fue ejecutada, pero quedó parcialmente bloqueada en Claude y Gemini;
por tanto es ejecución registrada, no validación exitosa de los tres runtimes.
El ciclo Git completo no se cerró: no se hizo merge, ni squash, ni pull final,
ni eliminación de rama/worktree. Tampoco se creó commit en esta acción. El
riesgo residual es la interferencia del contexto global y la falta de evidencia
del piloto y de validación cruzada en Claude/Gemini.

### Siguiente gate

Ejecutar el piloto desde un SHA limpio en un worktree: preservar las reglas
locales, clasificar los seis casos, comprobar que la suite local no empeora y
que el diff contiene solo scaffolding/documentación acordada, y dejar una draft
PR usable. El éxito permite proponer `v0.1.0`; requiere además autorización
explícita antes de etiquetar o hacer merge. Rollback: abandonar el worktree o
la rama antes de publicar, o hacer `git revert` del commit/PR después.
