return {
    {
        "RyanCargan/cmp-ai",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local cmp_ai = require("cmp_ai")
            local cmp_ai_config = require("cmp_ai.config")

            cmp_ai_config:setup({
                max_lines = 100,
                provider = "llama_cpp",
                provider_options = {
                    base_url = "http://127.0.0.1:8080/completion",
                    -- model auto-detected from llama-server /props endpoint
                    -- (empty triggers auto-detection: queries model_alias from
                    -- http://127.0.0.1:8080/props and picks rwkv vs standard FIM format)
                },
                run_on_every_keystroke = true,
            })
            cmp_ai.setup()
        end,
    },
}
