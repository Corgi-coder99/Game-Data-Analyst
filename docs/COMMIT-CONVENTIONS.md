# Commit conventions

This repository uses [Conventional Commits](https://www.conventionalcommits.org/). Write commit messages in English, in the imperative mood.

## Format

```
<type>(<optional scope>): <short summary>

<optional body: what and why, wrapped at about 72 characters>

<optional footer: BREAKING CHANGE, issue references>
```

- Summary: at most 72 characters, lower case after the colon, no trailing period.
- Add `!` after the type or scope, or a `BREAKING CHANGE:` footer, for incompatible changes (for example a data format change that breaks old saves or tests).

## Types

| Type | Use for |
|---|---|
| `feat` | A new gameplay feature or content |
| `fix` | A bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no behavior change |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `test` | Adding or changing tests |
| `build` | Project settings, export, dependencies |
| `ci` | Continuous integration configuration |
| `chore` | Maintenance that does not fit elsewhere |
| `art` | Sprites, palette, UI theme (project-specific) |
| `data` | Game data in `data/*.json`, balance numbers (project-specific) |

## Scopes (suggested)

`sim`, `world`, `ui`, `v2`, `data`, `tests`, `tools`, `style-bible`, `web`, `docs`.

## Examples

```
feat(world): add end-of-day review with boss trust changes
fix(sim): clamp conversion at the configured cap
data: rebalance demo starting cash after balance simulation
docs: translate game design documents to English
test(v2): add mouse-driven click tests for the report window
refactor(ui)!: move title screen strings into strings_v2.json
```

## Rules of thumb

- One logical change per commit; commit after each finished milestone.
- Do not commit secrets, API keys or personal data.
- Run the relevant tests before committing code changes.
- Do not rewrite history that has already been pushed.
