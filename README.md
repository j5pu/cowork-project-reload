# cowork-project-reload

Plugin para Claude Cowork que hace que el agente relea el `CLAUDE.md` y los skills de la carpeta del proyecto al empezar un chat y justo después de cada compactación, y que pide al resumen de la compactación que conserve reglas, decisiones y el paso en curso.

## El problema

Cuando una conversación se compacta, el historial se sustituye por un resumen. Los skills leídos a mitad de chat se pierden en ese resumen, y el agente sigue sin los procedimientos que tenía. Este plugin le ordena releerlos y le pide avisar si no puede recuperar lo que se estaba haciendo, en lugar de inventarlo.

## Qué hace cada hook del mod

Es un mod de hooks (`hooks/hooks.json` apunta a `hooks/register.ts`) con dos enganches. Ninguno hace llamadas de red, ni escribe ficheros, ni lee nada del sistema.

| Evento | Qué hace exactamente |
|---|---|
| `session.compact` | Se dispara cuando se va a compactar la conversación **principal** (no los subagentes). **Añade al campo `instructions` de esa compactación un texto fijo**: copiar literalmente las reglas, las decisiones y el paso en curso en secciones propias, y escribir "no consta" si algo no está claro. Si ya había instrucciones, las conserva y añade las suyas detrás. No cambia nada más de la llamada y deja pasar el resultado tal cual. Si el hook falla, la compactación sigue normal (`catch`). |
| `prompt.context` | Al construir el contexto, **añade un bloque de texto fijo**: en un chat nuevo, leer entero `CLAUDE.md`, listar los skills de `.claude/skills/*/SKILL.md` y leer completo el que encaje con la tarea; tras una compactación, lo mismo más contrastar el resumen con lo releído y, si no se puede recuperar qué se hacía o qué se decidió, parar y avisar. Si no hay carpeta conectada, el agente lo dice en una línea. |

El texto añadido es siempre el mismo: no copia ni procesa mensajes del usuario.

## Instalación

En Cowork: Personalizar → Plugins → Añadir → marketplace `j5pu/cowork-project-reload`.

En Claude Code (2.1.287 o posterior, por los mods):

```
/plugin install cowork-project-reload --marketplace j5pu/cowork-project-reload
```

## Estado de las pruebas

- `claude plugin test` pasa 4 de 4 con Claude Code 2.1.299, incluida la carga real en el motor (el bloque llega al contexto).
- Carga en una sesión real con el plugin instalado: el módulo se carga y se admite (`loaded; events: session.compact, prompt.context`).
- **Sin verificar:** en la sesión real, el log mostró `bypassed by cc-plugin-sec-default (tier user)` para ambos eventos y el resumen salió con la estructura estándar, sin las secciones REGLAS / DECISIONES / PASO EN CURSO. No está demostrado todavía que el mod modifique el resumen en una sesión real.
- No verificado dentro de Cowork.

## Estructura

```
.claude-plugin/plugin.json        manifiesto
.claude-plugin/marketplace.json   catálogo de un solo plugin
hooks/hooks.json                  registra el módulo
hooks/register.ts                 los dos enganches
hooks/register.test.ts            pruebas (bun test / claude plugin test)
```

## Licencia

MIT.
