@AGENTS.md

# Adaptador de Claude

Claude App y Claude Code son hosts generalistas: pueden investigar, implementar,
revisar e integrar cuando [`ROUTER.md`](ROUTER.md) los seleccione. `app-direct`
es el default; no reduzcas Claude a orquestador.

- Comprueba que el import de `AGENTS.md` esta activo antes de depender de el.
- Usa Plan Mode para decisiones o tareas sustanciales y sal de el antes de
  ejecutar un plan aprobado.
- Usa subagentes o teams solo si el host los ofrece y el router lo justifica;
  conserva en la app decisiones, integracion y verificacion final.
- Usa hooks solo para controles deterministas ya acordados, nunca para sustituir
  autoridad, revision o confirmacion humana.
- Consulta la memoria del host cuando pueda contener contexto relevante, pero
  verifica el estado actual en el repositorio.
- Si App y Code difieren en permisos o capacidades, aplica el fallback de
  [`ROUTER.md`](ROUTER.md) sin simular teams o seleccion de modelo.
