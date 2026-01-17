# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

clauder.nvim is a Neovim plugin that provides a git modified files browser, similar to oil.nvim but for git status. It displays files with diff statistics (+added/-removed lines) and allows opening side-by-side diffs.

## Architecture

### Module Structure

The plugin follows standard Neovim plugin architecture:

- `plugin/clauder.lua` - Entry point, registers `:Clauder` command (loaded once by Neovim)
- `lua/clauder/init.lua` - Main module, handles buffer lifecycle and initialization
- `lua/clauder/view.lua` - Rendering engine, manages buffer display and caching
- `lua/clauder/git.lua` - Git operations wrapper (status, diff stats, HEAD content)
- `lua/clauder/actions.lua` - User actions (select, close, refresh, help)
- `lua/clauder/config.lua` - Configuration management with defaults
- `lua/clauder/util.lua` - Shared utilities (system calls, keymaps)

### Key Design Patterns

**Singleton buffer**: `init.lua` tracks a single `_bufnr` globally. Calling `:Clauder` multiple times switches to existing buffer rather than creating new ones.

**Entry caching**: `view.lua` maintains `_cache[bufnr] = entries[]` to map line numbers to file data. Cache is cleared on BufDelete.

**Two-pass rendering**: `view.render()` calculates column widths in first pass, then formats with fixed-width padding for aligned display.

**Diff stats aggregation**: `git.get_diff_stats()` combines staged (`--cached`) and unstaged changes. Untracked files count total lines as "added".

**Buffer replacement behavior**: Unlike plugins that open in splits, clauder replaces current buffer (like oil.nvim) via `nvim_set_current_buf()`.

### Data Flow

1. `:Clauder` → `init.open()` → `git.get_modified_files()`
2. `git.get_modified_files()` calls `git.get_diff_stats()` and `git status --porcelain`
3. Returns `{filename, status, added, removed}[]` entries
4. `view.render()` calculates column widths, formats lines, applies highlights
5. User presses `<CR>` → `actions.select()` → `git.get_head_content()` + `diffthis`

## Development

### Testing Changes

Since this is a Neovim plugin, test by:

1. Source the plugin in a running Neovim instance:
   ```vim
   :luafile plugin/clauder.lua
   :lua package.loaded.clauder = nil  " Force reload
   :lua require('clauder').open()
   ```

2. Or restart Neovim if plugin is in runtimepath

3. Verify with files having varied line counts to test column alignment

### Display Format

The view renders entries as:
```
+{right-aligned-adds}/-{right-aligned-removes}  {filename}
```

Example with max_add=3, max_rem=1:
```
+  2/-0  file.lua
+ 88/-1  another.lua
+160/-0  bigger.lua
```

Highlights: `ClauderAdd` for +X, `ClauderRemove` for -Y (linked to diffAdded/diffRemoved).

### Git Status Codes

`git status --porcelain` returns 2-char status:
- `??` = untracked (expand directories recursively)
- ` M` = modified unstaged
- `M ` = modified staged
- `MM` = modified both staged and unstaged

See `git.get_modified_files()` for handling logic.

### Diff View Implementation

`actions.select()` creates side-by-side diff:
- Left: scratch buffer with HEAD content (`git show HEAD:path`)
- Right: working file (or empty scratch if deleted)
- Both windows run `:diffthis` for vim's built-in diff mode
- Respects `config.options.diff.vertical` for split direction
