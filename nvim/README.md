# Neovim Keymap Cheatsheet

Leader is `<Space>`. Local leader is also `<Space>`.

## Core

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>sv` | Normal | Open netrw file explorer |
| `<leader>w` | Normal | Write current buffer |
| `<leader>o` | Normal, Visual | Update and source current file |
| `<leader>p` | Visual | Paste over selection without yanking it |
| `<leader>d` | Normal, Visual | Delete without yanking |
| `<Esc>` | Normal | Clear search highlight |

## Search And Files

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>/` | Normal | Fuzzy search current buffer |
| `<leader>sh` | Normal | Search help tags |
| `<leader>sk` | Normal | Search keymaps |
| `<leader>sf` | Normal | Search files, including hidden files |
| `<leader>ss` | Normal | Search Telescope builtins |
| `<leader>sw` | Normal | Search word under cursor |
| `<leader>sg` | Normal | Live grep |
| `<leader>sd` | Normal | Search diagnostics |
| `<leader>sr` | Normal | Resume last Telescope picker |
| `<leader>s.` | Normal | Search recent files |
| `<leader>s/` | Normal | Live grep in open files |
| `<leader>sn` | Normal | Search Neovim config files |

## LSP And Diagnostics

LSP maps are buffer-local and are created after an LSP attaches.

| Key | Mode | Action |
| --- | --- | --- |
| `grn` | Normal | Rename symbol |
| `gra` | Normal, Visual | Code action |
| `gr` | Normal | Find references |
| `gri` | Normal | Go to implementation |
| `gd` | Normal | Go to definition |
| `grD` | Normal | Go to declaration |
| `gO` | Normal | Document symbols |
| `gW` | Normal | Workspace symbols |
| `grt` | Normal | Go to type definition |
| `<leader>th` | Normal | Toggle inlay hints, when supported |
| `[d` | Normal | Get previous diagnostic |
| `]d` | Normal | Get next diagnostic |
| `gh` | Normal | Open diagnostic float |

## Formatting

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>f` | Normal, Visual, Select, Operator-pending | Format buffer or range with Conform |

## Git

| Key | Mode | Action |
| --- | --- | --- |
| `do` | Normal | Preview current hunk inline with Gitsigns |
| `dp` | Normal | Reset current hunk with Gitsigns |

## Harpoon

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>e` | Normal | Toggle Harpoon quick menu |
| `<leader>a` | Normal | Add current file to Harpoon |
| `<leader>1` | Normal | Jump to Harpoon file 1 |
| `<leader>2` | Normal | Jump to Harpoon file 2 |
| `<leader>3` | Normal | Jump to Harpoon file 3 |
| `<leader>4` | Normal | Jump to Harpoon file 4 |
| `<C-P>` | Normal | Previous Harpoon file |
| `<C-N>` | Normal | Next Harpoon file |

## OpenCode

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>oa` | Normal, Visual | Ask OpenCode with `@this` context |
| `<leader>os` | Normal, Visual | Select OpenCode prompt context |
| `go` | Normal, Visual | OpenCode operator: append range |
| `goo` | Normal | OpenCode operator: append current line |
| `<S-C-u>` | Normal | Scroll OpenCode session up half a page |
| `<S-C-d>` | Normal | Scroll OpenCode session down half a page |

## Which-Key

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>?` | Normal | Show buffer-local keymaps |

## Completion: blink.cmp Defaults

The config uses `keymap = { preset = "default" }`.

| Key | Mode | Action |
| --- | --- | --- |
| `<C-Space>` | Insert | Show completion menu, show docs, or hide docs |
| `<C-e>` | Insert | Hide completion menu |
| `<C-y>` | Insert | Select and accept completion |
| `<Up>` / `<Down>` | Insert | Select previous or next completion |
| `<C-p>` / `<C-n>` | Insert | Select previous or next completion |
| `<C-b>` / `<C-f>` | Insert | Scroll completion documentation up or down |
| `<Tab>` / `<S-Tab>` | Insert | Jump forward or backward through snippets |
| `<C-k>` | Insert | Show or hide signature help |

## Text Objects: mini.ai Defaults

`mini.ai` extends `a` and `i` textobjects in Visual and operator-pending modes.

| Key | Mode | Action |
| --- | --- | --- |
| `a` | Visual, Operator-pending | Around textobject prefix |
| `i` | Visual, Operator-pending | Inside textobject prefix |
| `an` / `in` | Visual, Operator-pending | Next around or inside textobject |
| `al` / `il` | Visual, Operator-pending | Last around or inside textobject |
| `g[` / `g]` | Normal | Go to left or right edge of around textobject |

Common textobject identifiers: `(`, `[`, `{`, `<`, `)`, `]`, `}`, `>`, `b` for bracket alias, quotes with `"`, `'`, or `` ` ``, `q` for quote alias, `t` for tag, `f` for function call, `a` for argument, and `?` for a prompted textobject.

## Surround: mini.surround

This config customizes the default `mini.surround` mappings.

| Key | Mode | Action |
| --- | --- | --- |
| `sa` | Normal, Visual | Add surrounding |
| `ds` | Normal | Delete surrounding |
| `fs` | Normal | Find surrounding to the right |
| `sF` | Normal | Find surrounding to the left |
| `sh` | Normal | Highlight surrounding |
| `rs` | Normal | Replace surrounding |
| `l` suffix | Normal | Use previous surrounding search, for example `dsl)` |
| `n` suffix | Normal | Use next surrounding search, for example `dsn)` |

## Move: mini.move

This config customizes the default `mini.move` mappings.

| Key | Mode | Action |
| --- | --- | --- |
| `<M-h>` | Visual | Move selection left |
| `<M-l>` | Visual | Move selection right |
| `J` | Visual | Move selection down |
| `K` | Visual | Move selection up |
| `<M-h>` | Normal | Move current line left |
| `<M-l>` | Normal | Move current line right |
| `<M-j>` | Normal | Move current line down |
| `<M-k>` | Normal | Move current line up |

## Pairs: mini.pairs Defaults

`mini.pairs` creates insert-mode autopair mappings for `(`, `[`, `{`, `)`, `]`, `}`, single quotes, double quotes, and backticks. It also handles pair-aware `<BS>` and `<CR>` behavior.

## Sneak Defaults

`vim-sneak` uses its default mappings.

| Key | Mode | Action |
| --- | --- | --- |
| `s{char}{char}` | Normal, Visual | Jump to next occurrence of two characters |
| `S{char}{char}` | Normal | Jump to previous occurrence of two characters |
| `Z{char}{char}` | Visual | Jump to previous occurrence of two characters |
| `s{char}<Enter>` | Normal, Visual | Jump to next occurrence of one character |
| `S{char}<Enter>` | Normal | Jump to previous occurrence of one character |
| `Z{char}<Enter>` | Visual | Jump to previous occurrence of one character |
| `s<Enter>` | Normal, Visual | Repeat last Sneak |
| `S<Enter>` | Normal | Repeat last Sneak backward |
| `Z<Enter>` | Visual | Repeat last Sneak backward |
| `;` | Normal, Visual | Next Sneak match |
| `,` or `\` | Normal, Visual | Previous Sneak match |
| `[count]s{char}{char}` | Normal | Sneak with vertical scope |
| `[count]S{char}{char}` | Normal | Backward Sneak with vertical scope |
| `{operator}z{char}{char}` | Operator-pending | Operate to next Sneak match |
| `{operator}Z{char}{char}` | Operator-pending | Operate to previous Sneak match |
| `<Space>` or `<Esc>` | Sneak label mode | Exit label mode |
| `<Tab>` | Sneak label mode | Next label page |
| `<BS>` or `<S-Tab>` | Sneak label mode | Previous label page |

## Snacks Picker Defaults

`snacks.nvim` picker defaults are active. This config also adds `<A-a>` in picker input to send the selected item to OpenCode.

| Key | Mode | Action |
| --- | --- | --- |
| `<A-a>` | Picker Normal, Insert | Send selected picker item to OpenCode |
| `/` | Picker | Toggle focus between input and list |
| `<CR>` | Picker | Confirm selection |
| `<S-CR>` | Picker | Pick window and jump |
| `<Esc>` / `q` | Picker | Cancel picker |
| `j` / `k` or `<Down>` / `<Up>` | Picker | Move down or up |
| `<C-j>` / `<C-k>` | Picker | Move down or up |
| `<C-n>` / `<C-p>` | Picker | Move down or up |
| `gg` / `G` | Picker | Go to top or bottom |
| `<Tab>` / `<S-Tab>` | Picker | Select item and move next or previous |
| `<C-a>` | Picker | Select all |
| `<C-b>` / `<C-f>` | Picker | Scroll preview up or down |
| `<C-u>` / `<C-d>` | Picker | Scroll list up or down |
| `<C-q>` | Picker | Send selection to quickfix list |
| `<C-s>` | Picker | Open in split |
| `<C-v>` | Picker | Open in vertical split |
| `<C-t>` | Picker | Open in tab |
| `<A-f>` | Picker | Toggle follow |
| `<A-h>` | Picker | Toggle hidden files |
| `<A-i>` | Picker | Toggle ignored files |
| `<A-r>` | Picker input | Toggle regex |
| `<A-m>` | Picker | Toggle maximize |
| `<A-p>` | Picker | Toggle preview |
| `<A-w>` | Picker | Cycle picker window |
| `?` | Picker | Toggle picker help |
