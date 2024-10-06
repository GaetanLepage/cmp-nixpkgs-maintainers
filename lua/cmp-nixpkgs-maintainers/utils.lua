M = {}

local config = require 'cmp-nixpkgs-maintainers.config'

local prefix = "[cmp-nixpkgs-maintainers] "

M.log_debug = function(msg)
    if config.debug then
        vim.notify(
            prefix .. msg,
            vim.log.levels.DEBUG
        )
    end
end

M.log_info = function(msg)
    vim.notify(
        prefix .. msg,
        vim.log.levels.INFO
    )
end

return M
