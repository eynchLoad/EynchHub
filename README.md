# Eynch Hub

Free script hub for Roblox. Keys are free, last 24 hours, and come from our Discord or from the key window.

## Run it

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/eynchLoad/EynchHub/main/loader.lua"))()
```

A key window opens. Press **GET KEY**, finish the short steps, paste the key, and press **VERIFY KEY & LOAD**.

## Supported games

| Game | Status |
|---|---|
| Run a Sari-Sari Store! | Working |

## Links

- Website and guide: https://eynch-hub-site.pages.dev
- Discord: https://discord.gg/54aGSfX6dN

## Layout

```
loader.lua        finds your game and runs its file
games/            one file per game
```

`loader.lua` holds the list of game IDs. To support a new game, add a file in `games/` and one line in `loader.lua`.
