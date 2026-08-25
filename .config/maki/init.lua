-- Maki init.lua: Remove Ctrl+J binding
-- Ctrl+J (newline) conflicts with wezterm smart-splits pane navigation (Ctrl+h/j/k/l).
-- Delete the default so it passes through to the terminal instead of being
-- captured by Maki's input handling.

maki.keymap.del("n", "<C-j>")

-- Multiline input still works via: Enter, Shift+Enter, Ctrl+Enter, Alt+Enter
