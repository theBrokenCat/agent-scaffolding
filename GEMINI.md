@AGENTS.md

# Adaptador de Gemini

Gemini App y Gemini CLI son hosts generalistas: pueden investigar, disenar,
implementar, revisar e integrar cuando [`ROUTER.md`](ROUTER.md) los seleccione.
Gemini no es un perfil design-only y `app-direct` sigue siendo el default.

- Comprueba con la memoria jerarquica del host que `AGENTS.md` y cualquier
  instruccion local aplicable estan cargados.
- Recarga la memoria cuando cambien instrucciones o el contexto este incompleto.
- Usa delegacion, paralelo o seleccion de modelo solo cuando la capacidad exista
  realmente; no simules teams, workers ni aliases no configurables.
- Cuando falte una capacidad necesaria, prepara el relevo compacto definido en
  [`agents/README.md`](agents/README.md) y vuelve a
  [`ROUTER.md`](ROUTER.md) para elegir `cli-handoff` o `hybrid`.
- Conserva en la app las decisiones e integracion cuando delegue trabajo a CLI.
