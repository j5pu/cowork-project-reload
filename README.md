<p align="center"><img src="assets/icon.svg" width="96" alt="cowork-project-reload"></p>

# cowork-project-reload

Plugin para Claude Cowork que evita que el agente "olvide" las reglas del proyecto, sobre todo después de una compactación.

## Qué hace

- **Chat nuevo:** le indica que lea el `CLAUDE.md` de la carpeta del proyecto y que liste los skills de `.claude/skills/` (al menos nombre y descripción), cargando el `SKILL.md` completo cuando una tarea encaje.
- **Antes de compactar:** pide al resumidor que copie literalmente las reglas, las decisiones y el paso en curso, y que marque como "no consta" lo que no esté claro en vez de inventarlo.
- **Después de compactar:** avisa al agente ("Ha habido compactación. Antes de seguir, relee CLAUDE.md, y los skills si estás en un proyecto."), le pide contrastar el resumen con lo releído y, si no puede recuperar qué se estaba haciendo o qué se había decidido, parar y avisar en lugar de suponer.

Si no hay carpeta de proyecto conectada, o no existen esos archivos, el agente lo dice en una línea y no inventa su contenido.

## Cómo funciona

Es un *mod* de Claude: un plugin con un módulo de hooks (`hooks/register.ts`) que engancha dos eventos.

| Evento | Qué hace |
| --- | --- |
| `session.compact` | Añade a las instrucciones del resumen la petición de copiar reglas, decisiones y paso en curso. Solo actúa en la conversación principal, no en subagentes. Si el hook falla, la compactación sigue con normalidad. |
| `prompt.context` | Añade un bloque de contexto: el aviso de "nuevo chat", o el de "ha habido compactación" la primera vez después de compactar. |

## Requisitos

- Claude Cowork en la app de escritorio. La app trae su propio Claude Code integrado, y los mods necesitan la versión **2.1.287 o posterior** (la app de escritorio 2.42304.0 incluye la 2.1.299).
- Que los mods estén activos para tu cuenta (ver "Estado de las pruebas").

## Instalación

En la app de escritorio: **Customize → Plugins → Add** y añade el marketplace `j5pu/cowork-project-reload`; después instala el plugin `cowork-project-reload`.

## Estado de las pruebas

Esto es lo que está comprobado y lo que no.

| | Estado |
| --- | --- |
| `claude plugin validate` (Claude Code 2.1.299) | **Pasa.** Detecta los hooks `session.compact` y `prompt.context`. |
| Pruebas automáticas (`hooks/register.test.ts`, 4 pruebas) | **Escritas, sin ejecutar.** `claude plugin test` responde que los módulos de hooks están desactivados en esta cuenta (`the rollout switch was saved off by an earlier session`, que persiste tras refrescar la sesión; según la documentación significa que los mods instalados están apagados de forma remota). |
| Funcionamiento en Cowork | **Sin probar.** No hay confirmación de que Cowork cargue los módulos de hooks de un plugin. |
| Funcionamiento en Claude Code | **Sin probar.** El plugin está pensado solo para Cowork. |

Mientras los mods sigan apagados para la cuenta, el plugin se instala pero sus hooks no se ejecutan.

## Estructura

```
.claude-plugin/plugin.json        manifiesto del plugin
.claude-plugin/marketplace.json   catálogo (este mismo repositorio)
hooks/hooks.json                  apunta al módulo de hooks
hooks/register.ts                 los hooks
hooks/register.test.ts            pruebas automáticas
assets/icon.svg                   icono
```

Los eventos y métodos de los mods pueden cambiar entre versiones de Claude Code; ante cualquier discrepancia, mandan las declaraciones de tipos que Claude Code genera en `.claude-plugin/types/` al cargar el plugin.
