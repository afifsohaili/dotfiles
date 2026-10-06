return {
  {
    "milanglacier/minuet-ai.nvim",
    event = "InsertEnter",
    opts = {
      provider = "openai_compatible",
      notify = "verbose",
      request_timeout = 2.5,
      throttle = 1500,
      debounce = 600,
      virtualtext = {
        auto_trigger_ft = { "lua", "python", "javascript", "typescript", "vue", "rust", "go" },
        keymap = {
          accept = "<C-y>",
          accept_line = "<C-l>",
          accept_n_lines = "<C-k>",
          next = "<C-]>",
          prev = "<C-h>",
          dismiss = "<C-x>",
        },
      },
      provider_options = {
        openai_compatible = {
          api_key = "OPENROUTER_API_KEY",
          end_point = "https://openrouter.ai/api/v1/responses",
          model = "mistralai/codestral-2508",
          name = "OpenRouter",
          stream = true,
          optional = {
            max_tokens = 56,
            top_p = 0.9,
            reasoning_effort = "none",
          },
        },
      },
    },
  },
}
