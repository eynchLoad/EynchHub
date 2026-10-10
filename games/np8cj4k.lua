-- Eynch Hub | Run a Sari-Sari Store!
-- Opens the key window for this game. The script is handed out by the key server for a valid key.
getgenv().EYNCH_GAME = "sari-sari"
loadstring(game:HttpGet("https://eynch-key.eynchhub.workers.dev/loader"))()
