# TUI: Terminal Interfaces from a Pipeline

Nushell 0.116 added the `tui` command family. It builds a picker, a form, or a multi-pane browser from a pipeline without a Rust project.

Use `input list --fuzzy` for a single pick. Use `tui` for a pick with a preview, a form with several fields, panes, tabs, or a live log. A full application with its own state machine still belongs in Ratatui.

The basics here were verified on Nushell 0.116.1 / 0.117.0. Upstream details were checked on 0.116.2 / 0.117.0; 0.116.1 changed streams, borders, and titles, so re-check visual details before relying on them.

## The Model

- Builders (`tui table`, `tui split`, `tui textbox`, …) append a widget to a `tui` value and pass it on. A builder always outputs a `tui` value, not the original rows.
- `tui run` shows the value on the alternate screen and blocks until the user submits or quits.
- `tui debug` renders the same value to a string, without a terminal, and can replay keys first.
- Both return one record: `{action, focused, selected, page, values, rows, live}`.
  - `action` is `submit` or `quit`; `tui debug` also returns `render` when the keys ended without either.
  - `selected` is the focused widget's selection.
  - `values` holds every widget's state by id: `values.table-0.index`, `values.name`.
- `tui debug` adds `screen`, `widgets`, `focus`, and `pages`.

```nu
ls | tui label --titlebar 'files' | tui table | tui run | get selected.name
tui textbox --id name | tui run | get values.name
```

## Commands

- `tui label` — static text; `--titlebar`, `--status`; a closure runs for the highlighted row.
- `tui menu [items]` — menu bar; items are strings or `{name, items?, action?}`; `&` marks a mnemonic.
- `tui textbox` — editable field; `--placeholder`, `--value`.
- `tui table` — navigable rows; `--columns`, `--multi`, `--index`, `--capture-keys`, `--on-select`.
- `tui select [items]` — radio or checkbox list; `--multi`, `--display`.
- `tui button label hook?` — runs the hook, or submits its label.
- `tui progress` — gauge from `--value`, the data, or `--from`; values above 1 are read against `--total`.
- `tui log` — append-only view; `--max-lines`.
- `tui tree` — nested records or a directory walk (`--walk`).
- `tui search` — filters lists in its scope; `--bind /`, `--fuzzy`, `--case-sensitive`, `--columns`.
- `tui preview` — text for the highlighted row; a file by default, or a closure result.
- `tui split [children]` — panes; `--vertical`, `--sizes`, `--ratio`.
- `tui box title [children]` — bordered group.
- `tui tab title [children]` — a page in the tab bar.
- `tui bind key hook` — a key active anywhere.
- `tui run hook?` — event loop; `--dialog`, `--size`, `--refresh`, `--no-mouse`.
- `tui debug hook?` — headless render; `--keys`, `--until`, `--size`, `--dialog`.

Every widget accepts `--id` and `--focus`. List widgets also accept `--title`, `--border`, `--data`, and `--from`.

## Layout

- Widgets in the outer pipeline stack top to bottom, one row each.
- Adjacent `tui button`s share one row, left to right.
- `tui split`, `tui box`, and `tui tab` take child widgets built in parentheses.
- Chrome (`tui label --titlebar`, `tui label --status`, `tui menu`) goes in the outer pipeline only.
- `tui tab` is outer-pipeline only and cannot nest; use `tui box` inside a split.
- `tui search` filters every list in the outer pipeline, or only the lists inside its container.

```nu
ls
| tui label --titlebar 'files'
| tui split --sizes [60% 1fr] [
    (tui box 'list' [ (tui search --bind /) (tui table --columns [name type size]) ])
    (tui preview { nu-highlight })
  ]
| tui label --status 'enter: pick  /: filter  q: quit'
| tui run
```

`--sizes` entries: an int is cells (`30`), `"30%"` is a share, `"1fr"` is a share of the remainder, `"min:10"` and `"max:40"` are bounds.

### Ids

- Auto ids number widgets by kind in tree order: `table-0`, `table-1`, `search-0`.
- An explicit `--id` is never renumbered; using the same explicit id twice is an error.
- Pass `--id` when something reads the widget by name (`--from`, `values.<id>`).
- Default focus is the first focusable widget; `--focus` moves it.

## Data Flow

Each widget shows the first available source:

1. its own `--data`, or the value piped into it inside a child list;
2. what its `--from` source produced;
3. the nearest container's data;
4. the outer pipeline's data.

```nu
ls | tui split [ (tui table) (tui tree) ] | tui run            # both read ls
tui split [ (ps | tui table) (ls | tui table) ] | tui run       # separate rows
```

A stream stays live while `tui run` is open. A `tui` value saved with `let` reads its stream on the first run; later runs show the finished rows. `--from <id>` follows the highlighted row:

```nu
ls | tui split [(tui tree --walk) (tui table --from tree-0 {|node| ls $node.name })] | tui run
```

## Hooks

A hook receives the state record as `$in` and as its first parameter if declared. Its output decides what happens:

- nothing — no change
- `{action: submit, selected: ...}` — close with that selection
- `{action: quit}` — close without a selection
- anything else — replaces the shared data list

```nu
ls
| tui table
| tui bind ctrl+r {|| ls }
| tui bind s {|state| {action: submit, selected: $state.selected.name} }
| tui run
```

## Testing with `tui debug`

`tui run` needs a real terminal. Use `tui debug` in scripts and agents, then hand the user the same pipeline ending in `tui run`.

```nu
[{name: a} {name: b}] | tui table | tui debug --keys [down enter] | select action selected
# => {action: submit, selected: {name: b}}
```

- `--keys` accepts tokens such as `enter`, `esc`, `tab`, arrows, `pageup`, `delete`, `ctrl+c`, `type:hello`, `click:COL,ROW`, and `scroll-down`.
- `--size [w h]` sets the canvas (default `[80 24]`).
- `--until` stops on a predicate over the state.
- `get widgets` shows each widget's `rect`, resolved columns, filtered rows, query, and `--from` source.

## Pitfalls

- A hook error goes to the status bar as `error:<msg>`. With no status label, the error is invisible.
- `q` quits only when no text field has focus; inside a search or text box it is a character. Esc leaves the field first.
- Enter on a text box submits the whole TUI with the text as `selected`; read `values` for multi-field forms.
