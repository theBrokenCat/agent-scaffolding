@AGENTS.md

# Adaptador de Claude

Claude App y Code pueden investigar, implementar y revisar: `app-direct` por
defecto, sin rol fijo de orquestador. Comprueba que el import resuelve en runtime.

Usa Plan Mode para decisiones sustanciales y sal antes de ejecutar un plan
aprobado. Hooks solo para controles deterministas acordados, nunca para sustituir
autoridad o revision. Consulta memoria relevante y verifica su vigencia.
Si App y Code difieren en capacidades, el lead aplica el fallback del router;
no simules teams, permisos o seleccion de modelo.
Al delegar, aplica [Claude: `Agent`](agents/README.md#claude-agent): fichas del
scaffolding, sin `Explore`/`general-purpose` ni override de `model`.
