# neotest-gdunit4

A [Neotest][1] adapter for [GdUnit4][2], a testing framework for the Godot game engine.

## Features

- Integrates GdUnit4 test discovery and execution with Neotest
- Uses the VSTest protocol over TCP to communicate with the GdUnit4 server
- Supports parallel test execution
- Shows test output and error messages

## Requirements

- Neovim >= 0.7.0
- [Neotest](https://github.com/nvim-neotest/neotest)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [Godot][3] with [GdUnit4][2] installed

## Installation

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use({
  "nvim-neotest/neotest",
  requires = {
    "nvim-lua/plenary.nvim",
    "brianrodri/neotest-gdunit4",
    -- your other adapters...
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-gdunit4").setup({
          host = "localhost", -- GdUnit4 server host
          port = 31002,       -- GdUnit4 server port
        })
      }
    })
  end
})
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "brianrodri/neotest-gdunit4",
    -- your other adapters...
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-gdunit4").setup({
          host = "localhost", -- GdUnit4 server host
          port = 31002,       -- GdUnit4 server port
        })
      }
    })
  end
}
```

## Usage

Before running tests, you need to start the Godot engine in your project with
the GdUnit4 plugin enabled. Then, after seeing the following message, you should
be ready to start running tests:

```vim
:lua require("neotest").run.run() " Run nearest test
:lua require("neotest").run.run(vim.fn.expand("%")) " Run current file
:lua require("neotest").run.run(vim.fn.getcwd()) " Run all tests in project
:lua require("neotest").summary.toggle() " Toggle summary panel
```

## Configuration

```lua
require("neotest").setup({
  adapters = {
    require("neotest-gdunit4").setup({
      host = "localhost", -- GdUnit4 server host (default: "localhost")
      port = 31002,       -- GdUnit4 server port (default: 31002)
      log_level = "info", -- Log level (default: "info")
    })
  }
})
```

## How It Works

This adapter:

1. Connects to the GdUnit4 server using TCP
2. Uses the VSTest protocol to communicate with the server
3. Discovers tests using the VSTest TestDiscovery protocol
4. Runs tests using the VSTest TestExecution protocol
5. Processes test results and sends them to Neotest

## Troubleshooting

If you encounter any issues:

1. Make sure the GdUnit4 server is running on the specified host and port
2. Check that your Godot scripts are recognized as test files by GdUnit4
3. Enable logging with `log_level = "debug"` for more detailed output

## Credits

- [Neotest](https://github.com/nvim-neotest/neotest) for the testing framework
- [GdUnit4](https://github.com/MikeSchulze/gdUnit4) for the Godot testing framework

## License

MIT

[1]: https://github.com/nvim-neotest/neotest
[2]: https://github.com/MikeSchulze/gdUnit4
[3]: https://godotengine.org/
