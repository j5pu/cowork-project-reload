# cowork-project-reload

Plugin para Claude Cowork que hace que el agente relea el `CLAUDE.md` y los skills de la carpeta del proyecto al empezar un chat y justo después de cada compactación. Así deja de "hacer lo que le da la gana" cuando se pierde el contexto original.

## El problema

Cuando una conversación se compacta, el historial se sustituye por un resumen. Los skills leídos a mitad de chat se pierden en ese resumen, y el agente sigue trabajando sin los procedimientos que tenía. Este plugin le recuerda releerlos y le pide que avise si no puede recuperar lo que se estaba haciendo, en lugar de inventarlo.

## Qué hace

Usa hooks clásicos (sin mods), que son los que Cowork y Claude Code cargan según la tabla oficial de plataformas:

| Hook | Cuándo | Qué hace |
|---|---|---|
| `SessionStart` (`startup`) | Al abrir un chat nuevo | Inyecta la orden de leer entero `CLAUDE.md`, listar los skills de `.claude/skills/*/SKILL.md` y leer cada uno completo cuando la tarea encaje. |
| `SessionStart` (`compact`) | Justo después de compactar | Misma orden, más: contrastar el resumen con lo releído y, si no se puede recuperar qué se hacía o qué se decidió, parar y avisar. |
| `PreCompact` | Justo antes de compactar | Emite instrucciones para que el resumen copie literalmente REGLAS, DECISIONES y PASO EN CURSO, marcando "no consta" lo dudoso. |

Si no hay carpeta de proyecto conectada, el agente lo dice en una línea y no inventa el contenido.

## Instalación

En Cowork: Personalizar → Plugins → Añadir → marketplace `j5pu/cowork-project-reload`.

En Claude Code (2.1.275 o posterior):

```
/plugin install cowork-project-reload --marketplace j5pu/cowork-project-reload
```

## Estado de las pruebas

Probado con Claude Code 2.1.299 (el que incluye la app de escritorio), con `--plugin-dir`:

- `SessionStart:startup`: el texto llega al modelo. Verificado.
- `SessionStart:compact`: se ejecuta tras `/compact` y queda registrado en la sesión como contexto añadido. Verificado.
- `PreCompact`: se ejecuta antes de `/compact` (estado 0). Sin embargo, en la prueba su texto solo aparece como salida del comando en la interfaz; el resumen generado mantuvo la regla y la decisión de la prueba, pero con la estructura estándar, no con las secciones REGLAS / DECISIONES / PASO EN CURSO. **No está demostrado que este hook modifique el resumen.**
- Tras compactar, el agente recupera una regla escrita en `CLAUDE.md` (prueba real con una palabra clave de proyecto). Verificado.
- Carga dentro de Cowork: no verificada todavía; la documentación oficial indica que los hooks se cargan en Cowork, pero falta una prueba real en un chat.

## Cómo probarlo

```
tests/run.sh                      # pruebas de los scripts
tests/run.sh /ruta/a/claude       # además, prueba real con Claude Code (startup, /compact, relectura)
```

## Estructura

```
.claude-plugin/plugin.json        manifiesto
.claude-plugin/marketplace.json   catálogo de un solo plugin
hooks/hooks.json                  registro de los hooks
hooks/session-start.sh            texto de SessionStart (startup | compact)
hooks/pre-compact.sh              texto de PreCompact
tests/run.sh                      pruebas
```

## Licencia

MIT.
