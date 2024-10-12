local maintainers = require 'cmp-nixpkgs-maintainers.maintainers'

maintainers.refresh_cache_if_needed()

local source = {}

source.new = function()
    return setmetatable({}, { __index = source })
end

source.is_available = function()
    -- Only enable when editing PR descriptions (i.e. markdown files located in /tmp)

    local filepath = vim.fn.expand('%')

    return (vim.o.filetype == 'markdown') and vim.startswith(filepath, "/tmp")
end

source.get_trigger_characters = function()
    return { '@' }
end

source.complete = function(self, request, callback)
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
    else
        callback { isIncomplete = true }
    end
end

return source
