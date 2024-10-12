local maintainers = require 'cmp_nixpkgs_maintainers.maintainers'

local cmp_config = require 'cmp.config'


---@class cmp_nixpkgs_maintainers.Option
---@field public cache_lifetime integer

---@type cmp_nixpkgs_maintainers.Option
local defaults = {
    cache_lifetime = 14,
}

---@return cmp_nixpkgs_maintainers.Option
local validate_option = function(option)
    option = vim.tbl_deep_extend('keep', option, defaults)
    vim.validate({
        cache_lifetime = { option.cache_lifetime, 'number' },
    })
    return option
end


local source = {}

source.new = function()
    local self = setmetatable({}, { __index = source })

    local source_config = cmp_config.get_source_config "nixpkgs_maintainers" or {}
    local config = validate_option(source_config.option or {})

    maintainers.refresh_cache_if_needed(config.cache_lifetime)

    return self
end

-- @return boolean
source.is_available = function()
    -- Only enable when editing PR descriptions (i.e. markdown files located in /tmp)

    local filepath = vim.fn.expand('%')

    return (vim.o.filetype == 'markdown') and vim.startswith(filepath, "/tmp")
end

source.get_trigger_characters = function()
    return { '@' }
end

source.complete = function(_, request, callback)
    option = validate_option(request.option)

    local input = string.sub(
        request.context.cursor_before_line,
        request.offset - 1
    )
    local prefix = string.sub(
        request.context.cursor_before_line,
        1,
        request.offset - 1
    )

    local should_trigger = (
        vim.startswith(input, "@")
        and (prefix == "@" or vim.endswith(prefix, " @"))
    )

    if should_trigger then
        -- keys: nixpkgs handle
        -- values: github handle
        local maintainers_table = maintainers.get_cached_maintainers(option.cache_lifetime)

        local items = {}
        for alias, github_handle in pairs(maintainers_table) do
            table.insert(items, {
                label = string.format("%s (@%s)", alias, github_handle),
                textEdit = {
                    newText = "@" .. github_handle,
                    range = {
                        start = {
                            line = request.context.cursor.row - 1,
                            character = request.context.cursor.col - 1 - #input,
                        },
                        ['end'] = {
                            line = request.context.cursor.row - 1,
                            character = request.context.cursor.col - 1,
                        },
                    },
                }
            })
        end
        callback {
            items = items,
            isIncomplete = true,
        }
    else
        callback { isIncomplete = true }
    end
end

return source
