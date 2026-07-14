---
name: render
description: Optional. Render a markdown spec into a single self-contained HTML page with per-section diagrams (inline SVG by default; raster via the bundled scripts only when uv and OPENAI_API_KEY exist). Markdown stays the source of truth; the output is a derived artifact. Invoke explicitly with a spec path.
disable-model-invocation: true
argument-hint: [specs/NNN-name.md]
allowed-tools: Read, Grep, Glob, Write, Bash(uv run:*), Bash(mkdir:*), Bash(git status:*), Bash(git check-ignore:*)
---
Render the spec at: $ARGUMENTS

This skill is optional, like `/pr-review`. It produces presentation output only; it never edits the spec, and nothing else in the workflow depends on it.

Steps:

1. Read the target spec in full. Any format vintage renders; old-format specs render the sections they have. Never modify the source.
2. Author `specs/html/<spec-name>.html` (create `specs/html/` if missing): one self-contained file, all CSS inline in a single `<style>` block using CSS custom properties for a minimal professional theme. No external stylesheets, scripts, fonts, or network fetches of any kind.
3. Give each major section (problem, solution, each phase) one focused diagram, first capable tier wins:
   - **Inline SVG (default, zero dependency).** Author the diagram as inline SVG styled by the page's own custom properties. Node, flow, and architecture diagrams, which is most of what a spec needs, belong here.
   - **Raster via the bundled scripts**, only when a diagram genuinely needs photographic or richly textured illustration: if `uv` is on PATH and `OPENAI_API_KEY` is set, first `mkdir -p specs/html/<spec-name>/` (the scripts do not create parent directories), then run `uv run <skill-dir>/scripts/generate_gpt_image.py "<prompt>" specs/html/<spec-name>/<slot>.png --size 1536x1024 --quality high` (edit with `uv run <skill-dir>/scripts/edit_gpt_image.py "<instruction>" <output.png> <input.png>`). If the API rejects the default model, pass `--model` with a current image model and continue. Generated PNGs land in `specs/html/<spec-name>/` as the editable sources, and the page embeds each one as a base64 `data:` URI, so the HTML stays a single self-contained file even with raster diagrams (sharing the one file never breaks an image).
   - **Skip**: without those tools, render the slot as SVG anyway or leave it out with a one-line note naming the missing backend. The page always renders.
   Diagram rules: one or two core ideas, drawn for professional engineers, under 10 words of visible text, wide aspect for raster.
4. Keep every diagram consistent with the page theme (same palette and typography).
5. Report the output path and which tier served each diagram. Do not open a browser; if the project names a preferred viewer in CLAUDE.md, mention the command.

Secrets: `OPENAI_API_KEY` comes from the environment or `.env` (gitignored). Never write it to any file, and never commit it.

Output is a derived artifact: `specs/html/` is gitignored on fresh installs, regenerate at will. A project that wants to publish the rendered pages removes that ignore line. In a repo adopted before this skill existed (`--update` never touches your `.gitignore`), check `git check-ignore specs/html` first; if it is not ignored, add the `specs/html/` line to `.gitignore` or commit the output deliberately, and say which happened in the report.

Note on backends: the Codex CLI was evaluated as a subscription-licensed raster tier and dropped; as of codex 0.137.0 its only image facility is attaching input images, it cannot emit generated images. If a later codex version adds image output, it belongs between the SVG and script tiers.

Next: the spec is unchanged and the loop continues wherever it was. Re-run `/render` any time the spec changes.
