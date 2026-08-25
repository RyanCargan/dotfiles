-- smart-splits.nvim removed 2026-08-25: value prop didn't justify the
-- nvim/wezterm coupling (a `Ctrl+h/j/k/l` plugin that needed both sides
-- loaded and in sync). Re-add here if the workflow makes sense later.
--
-- This file is intentionally a no-op stub. The terminal-split helpers
-- (open_term, smart_rebalance, <leader>tt/ts/to/ta/ar, TermOpen autocmd,
-- t <Esc>) that used to live inside the smart-splits config function
-- were unused outside this file, so they were dropped along with it.
return {}
