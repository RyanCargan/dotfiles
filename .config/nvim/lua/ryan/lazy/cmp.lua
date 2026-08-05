return {
    {
        "RyanCargan/cmp-ai",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local cmp_ai = require("cmp_ai.config")

            cmp_ai:setup({
                max_lines = 100,
                provider = "llama_cpp",
                provider_options = {
                    base_url = "http://127.0.0.1:8080/completion",
                    model = "rwkv7-g1g-2.9b-Q4_K_M",
                },
                run_on_every_keystroke = true,
            })
        end,
    },
}