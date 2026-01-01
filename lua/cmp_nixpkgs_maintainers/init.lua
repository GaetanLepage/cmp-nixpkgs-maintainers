local maintainers = require 'cmp_nixpkgs_maintainers.maintainers'

local cmp_config = require 'cmp.config'


---@class cmp_nixpkgs_maintainers.Option
---@field public cache_lifetime integer
---@field public silent boolean
---@field public nixpkgs_flake_uri string

---@type cmp_nixpkgs_maintainers.Option
local defaults = {
    cache_lifetime = 14,
    silent = false,
    nixpkgs_flake_uri = "nixpkgs",
}

---@return cmp_nixpkgs_maintainers.Option
local validate_option = function(option)
    option = vim.tbl_deep_extend('keep', option, defaults)
    vim.validate(
        'cache_lifetime',
        option.cache_lifetime,
        'number'
    )
    vim.validate(
        'silent',
        option.silent,
        'boolean'
    )
    vim.validate(
        'nixpkgs_flake_uri ',
        option.nixpkgs_flake_uri,
        'string'
    )
    return option
end


local source = {}

source.new = function()
    local self = setmetatable({}, { __index = source })

    local source_config = cmp_config.get_source_config "nixpkgs_maintainers" or {}
    local config = validate_option(source_config.option or {})

    maintainers.silent = config.silent
    maintainers.cache_lifetime_days = config.cache_lifetime
    maintainers.nixpkgs_flake_uri = config.nixpkgs_flake_uri
    maintainers.refresh_cache_if_needed()

    return self
end

-- @return boolean
source.is_available = function()
    -- Only enable when editing PR descriptions (i.e. markdown files located in /tmp or /private/var)
    if vim.bo.filetype ~= 'markdown' then
        return false
    end

    local filepath = vim.fn.expand('%:p')
    local is_in_linux_tmp = vim.startswith(filepath, "/tmp")
    local is_in_darwin_tmp = vim.startswith(filepath, "/private/var/")

    return is_in_linux_tmp or is_in_darwin_tmp
end

source.get_trigger_characters = function()
    return { '@' }
end

source.complete = function(_, request, callback)
    -- "cc @Joh"
    local line_before_cursor = request.context.cursor_before_line
    local request_offset_prev = request.offset - 1

    -- "cc @"
    local prefix = line_before_cursor:sub(1, request_offset_prev)

    -- "@Joh"
    local input = line_before_cursor:sub(request_offset_prev)

    local should_trigger = (
        vim.startswith(input, "@")
        and (prefix == "@" or vim.endswith(prefix, " @"))
    )

    if not should_trigger then
        return callback { isIncomplete = true }
    end

    -- keys: nixpkgs handle
    -- values: github handle
    local maintainers_table = maintainers.get_cached_maintainers()

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
end

return source
