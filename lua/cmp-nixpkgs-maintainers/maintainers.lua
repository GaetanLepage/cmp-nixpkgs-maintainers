-- local cache
local path_to_json = vim.fn.stdpath("cache") .. "/nixpkgs-maintainer.json"
local path_to_timestamp = vim.fn.stdpath("cache") .. "/nixpkgs-maintainer.json.timestamp"

local cache_lifetime_days = vim.g.cache_lifetime_days or 12
local cache_lifetime_s = cache_lifetime_days * (24 * 60 * 60)

local json_exists = function()
    return vim.fn.filereadable(path_to_json) == 1
end

-- 3 cases:
-- - 1) Cache is absent:
--      * download now (blocking)
--      * once done, return the obtained new file
-- - 2) Cache is outdated
--      * download in the background (non-blocking)
--      * return the old cache
-- - 3) Cache is up-to date
--      * return the cache

local fetch_json = function(blocking)
    -- vim.notify("Fetching maintainer list", vim.log.levels.INFO)

    local on_exit = function(out)
        local write_file_and_setup_source = function()
            local json_file = io.open(path_to_json, "w")
            assert(json_file)
            json_file:write(out.stdout)
            json_file:close()

            -- Write a timestamp to remember when this file has been cached
            local timestamp_file = io.open(path_to_timestamp, "w")
            assert(timestamp_file)
            timestamp_file:write(
                os.time()
            )
            timestamp_file:close()
        end

        write_file_and_setup_source()

        -- vim.schedule(write_file_and_setup_source)
    end

    vim.system(
        {
            "nix",
            "eval",
            "--json",
            "nixpkgs/master#lib.maintainers",
            "--apply", 'builtins.mapAttrs (_: v: v.github or "")',
            "--refresh",
        },
        { text = true, },
        on_exit
    ):wait()
end

local json_outdated = function()
    local timestamp = vim.fn.readfile(path_to_timestamp)[1]

    local cache_age_s = os.difftime(os.time(), timestamp)
    return cache_age_s > cache_lifetime_s
end

if not json_exists() then
    vim.notify(
        "Maintainers list not found. Downloading from nixpkgs.",
        vim.log.levels.INFO
    )
    fetch_json()
    vim.notify(
        "Finished downloading.",
        vim.log.levels.DEBUG
    )
elseif json_outdated() then
    vim.notify(
        "maintainers outdated. Refreshing in the background.",
        vim.log.levels.INFO
    )
    fetch_json()
else
    vim.notify(
        "maintainers up to date",
        vim.log.levels.DEBUG
    )
end

local maintainers = vim.fn.json_decode(
    vim.fn.readfile(path_to_json)
)

return maintainers
