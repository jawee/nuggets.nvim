# nuggets.nvim

## Features
- List outdated packages
- [Fidget](https://github.com/j-hui/fidget.nvim) notifications


## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
  "jawee/nuggets.nvim",
  config = function()
    require("nuggets").setup({})
    vim.keymap.set("n", "<leader>nu", "<cmd>Nuggets<CR>")
  end,
}
```

## Configuration

TODO

## Usage

- `Nuggets`
