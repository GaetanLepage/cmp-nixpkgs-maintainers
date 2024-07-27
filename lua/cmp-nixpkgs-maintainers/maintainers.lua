-- local cache_
local path_to_json = vim.fn.stdpath("cache") .. "/nixpkgs-maintainer.json"

local json_exists = function()
    return vim.fn.filereadable(path_to_json) == 1
end

local fetch_json = function()
    print("Fetching maintainer list")

    on_exit = function(out)
        local write_file_and_setup_source = function()
            local file = io.open(path_to_json, "w")
            assert(file)
            file:write(out.stdout)
            file:close()
            setup_source()
        end

        vim.schedule(write_file_and_setup_source)
    end

    vim.system(
        {
            "nix",
            "eval",
            "--json",
            "nixpkgs/master#lib.maintainers",
            "--apply", 'builtins.mapAttrs (_: v: v.github or "")',
        },
        { text = true, },
        on_exit
    )
end

local json_outdated = function()
    -- TODO
    return false
end

if not json_exists() then
    print("maintainers list not found.")
    fetch_json()
elseif json_outdated() then
    print("maintainers outdated.")
end

local maintainers = vim.fn.json_decode(
    vim.fn.readfile(path_to_json)
)

return maintainers
