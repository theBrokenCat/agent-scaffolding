# Perfiles de ejecucion

Un perfil combina esfuerzo, alias de modelo, gates de riesgo y mecanismo del
[`ROUTER.md`](../ROUTER.md). Limita el trabajo; no es una personalidad, no fija
un dominio y no concede autoridad.

## Esfuerzo

| Nivel | Cuando usarlo | Default operativo |
| --- | --- | --- |
| `fast` | Cambio pequeno, pregunta concreta o exploracion acotada | `app-direct`, una pasada, sin delegacion ni confirmacion |
| `standard` | Feature normal, diagnostico o analisis con varias evidencias | `app-direct`; un worker solo si aporta ahorro neto |
| `deep` | Seguridad, produccion, ambiguedad alta, integracion compleja o revision exigente | preflight y equipo solo si cumple el umbral |

## Aliases de modelo

Los aliases portables son `economy`, `balanced` y `frontier`. El mapping local
inicial es `economy -> Luna`, `balanced -> Terra` y `frontier -> Sol`. Es una
configuracion local, no una garantia ni un requisito del repositorio. Los hosts
sin selector usan el modelo disponible y registran el fallback.

Como punto de partida usa `fast / economy`, `standard / balanced` y
`deep / frontier`, pero mantenlos separados: un alias elige capacidad/coste; el
nivel limita proceso. Ninguno amplia permisos.

## Gates de riesgo

Los gates se combinan con cualquier nivel:

- **read-only:** ninguna escritura local o remota; hallazgos con evidencia.
- **write:** scope y paths definidos, baseline, diff y verificacion proporcional.
- **security:** redaccion, skill especializado, validacion de hallazgos y
  aprobacion para acciones intrusivas.
- **production:** estado observado, autorizacion explicita para actuar, rollback
  verificable y comprobacion posterior.
- **remote:** el ciclo global permite feature branches, checkpoint pushes y
  draft PR; merge, deploy/produccion, force-push, push a `main` y acciones
  destructivas siempre se confirman por separado.

Elige el nivel y alias mas bajos que cubran complejidad y riesgo. Si la seleccion
cambia coste o autoridad, aplica el preflight de [`ROUTER.md`](../ROUTER.md).

## Contexto

Carga contrato, instrucciones locales aplicables y evidencia minima. Los
dominios, tecnologias y criterios concretos pertenecen al brief del worker, no a
perfiles especializados. Usa los roles genericos de
[`agents/README.md`](../agents/README.md) y los limites de
[`policies/README.md`](../policies/README.md).
