# Settings Loader

This mod is an API for convenient settings (re)loading.

## API

The API is documentated using Lua Language Server annotations. An example is shown below:

```lua
teacher.settings = settings_loader.load_settings("teacher.", {
    recent_threshold = { -- actual key: teacher.recent_threshold
        stype = "integer", -- Type of the setting
        default = 172800, -- 2 days
    }
}, true)
```
