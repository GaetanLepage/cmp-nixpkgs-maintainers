-- keys: nixpkgs handle
-- values: github handle
local maintainers = require 'cmp-nixpkgs-maintainers.maintainers'

local source = {}

source.new = function()
    return setmetatable({}, { __index = source })
end

source.get_trigger_characters = function()
    return { '@' }
end

source.get_keyword_pattern = function()
    -- Add dot to existing keyword characters (\k).
    return [[\%(\k\|\.\)\+]]
end

source.complete = function(self, request, callback)
    print("TOTO")
end

return source
