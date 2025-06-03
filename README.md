# youtube.nvim

A Neovim plugin for searching and playing YouTube videos directly from your editor using `snacks.picker` with thumbnail previews.

## Features

- 🔍 Search YouTube videos with fuzzy finding
- 🖼️ Thumbnail previews in the picker
- ⚡ Fast initial results with background loading for more
- 🎬 Play videos in your preferred player
- 🔗 Direct URL playback support
- ⚙️ Fully configurable

## Requirements

- Neovim 0.10+
- [snacks.nvim](https://github.com/folke/snacks.nvim) with image support
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) for YouTube search
- `curl` for thumbnail downloads
- A video player (default: `open` on macOS)

## Installation

### Lazy.nvim

```lua
return {
  "benomahony/youtube.nvim",
}
```

That's it! The plugin will automatically:

- Set up the `:YouTube` command
- Create the `<leader>sy` keymap for YouTube search
- Configure sensible defaults

### Dependencies

Make sure you have snacks.nvim with image support:

```lua
return {
  "folke/snacks.nvim",
  opts = {
    picker = { enabled = true },
    image = { enabled = true },
  }
}
```

### Install Dependencies

```bash
# Install yt-dlp
brew install yt-dlp  # macOS
# or
pip install yt-dlp

# curl is usually pre-installed on most systems
```

## Snacks Image Configuration

For thumbnail previews to work, you need to configure snacks.nvim with image support. Add this to your snacks configuration:

```lua
require("snacks").setup({
  picker = { enabled = true },
  image = { enabled = true }, -- Required for thumbnail previews
})
```

## Configuration

```lua
require("youtube").setup({
  -- Video player command (first arg will be the URL)
  player_cmd = { "open" }, -- macOS default
  -- player_cmd = { "mpv" },        -- mpv
  -- player_cmd = { "vlc" },        -- VLC
  -- player_cmd = { "firefox" },    -- Browser
  
  -- Thumbnail cache directory
  cache_dir = nil, -- defaults to vim.fn.stdpath("cache") .. "/youtube_thumbnails"
  
  -- Search result limits
  initial_results = 10,  -- Fast initial load
  max_results = 100,     -- Background load limit
  
  -- Background loading delay (ms)
  background_delay = 500,
  
  -- Keymap (set to false to disable)
  keymap = "<leader>sy",
})
```

## Usage

### Commands

- `:YouTube` - Search YouTube videos

### Default Keymap

- `<leader>sy` - Search YouTube

### Example Workflow

1. Press `<leader>sy` or run `:YouTube`
2. Enter your search query
3. Browse results with thumbnail previews
4. Press `<CR>` to play the selected video
5. More results load automatically in the background

## Player Configuration Examples

### mpv

```lua
require("youtube").setup({
  player_cmd = { "mpv", "--ytdl-format=best" },
})
```

### VLC

```lua
require("youtube").setup({
  player_cmd = { "vlc" },
})
```

### Browser

```lua
require("youtube").setup({
  player_cmd = { "firefox" },
})
```

### Custom Script

```lua
require("youtube").setup({
  player_cmd = { "/path/to/your/player-script.sh" },
})
```

## Terminal Image Support

Different terminals have different image support capabilities:

- **Kitty**: Full support with `backend = "kitty"`
- **WezTerm**: Use `backend = "wezterm"`
- **iTerm2**: Use `backend = "iterm"`
- **Other terminals**: May have limited or no image support

If thumbnails don't appear, check your terminal's image support or disable images:

```lua
require("snacks").setup({
  image = { enabled = false }
})
```

## Troubleshooting

### No results found

- Ensure `yt-dlp` is installed and in your PATH
- Check your internet connection
- Try a different search query

### Thumbnails not showing

- Verify snacks.nvim image support is configured
- Check your terminal supports images
- Ensure `curl` is available
- Check cache directory permissions

### Video won't play

- Verify your player command is correct
- Test the player command manually
- Check if the player supports YouTube URLs

### Performance issues

- Reduce `initial_results` for faster startup
- Increase `background_delay` for slower systems
- Clear thumbnail cache: `rm -rf ~/.cache/nvim/youtube_thumbnails`

## License

MIT
