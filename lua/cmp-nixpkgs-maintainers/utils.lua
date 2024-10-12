M = {}

local config = require 'cmp-nixpkgs-maintainers.config'

local prefix = "[cmp-nixpkgs-maintainers] "

M.log = function(msg)
    print(prefix .. msg)
end

M.log_debug = function(msg)
    if config.debug then
        M.log(msg)
    end
end


return M
