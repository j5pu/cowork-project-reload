<p align="center"><img src="assets/icon.svg" width="96" alt="cowork-project-reload"></p>

# cowork-project-reload

Plugin para Claude (Cowork / Claude Code) que evita que el agente "olvide" las reglas del proyecto.

- **Chat nuevo:** le indica que lea el `CLAUDE.md` de la carpeta del proyecto y que liste los skills de `.claude/skills/` (al menos nombre y descripción), cargando el completo cuando una tarea encaje.
- **Antes de compactar:** pide al resumidor que copie literalmente reglas, decisiones y paso en curso.
- **Después de compactar:** "Ha habido compactación. Antes de seguir, relee CLAUDE.md, y los skills si estás en un proyecto." Si no puede recuperar lo que se hacía, para y avisa.

## Instalación

En la app de escritorio: pulsa **+** junto al cuadro de texto → **Plugins** → **Add marketplace** con `<owner>/<repo>` → **Add plugin**.

En un terminal de Claude Code:

```
/plugin install cowork-project-reload --marketplace <owner>/<repo>
```

Desde la shell:

```
claude plugin install cowork-project-reload --marketplace <owner>/<repo>
```

> En organizaciones con configuración gestionada, los eventos de compactación y contexto inicial solo se ejecutan si la organización incluye este plugin en su configuración gestionada.
