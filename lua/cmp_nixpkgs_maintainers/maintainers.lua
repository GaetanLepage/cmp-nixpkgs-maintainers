-- local cache
local path_to_json = vim.fn.stdpath("cache") .. "/nixpkgs-maintainer.json"
local path_to_timestamp = vim.fn.stdpath("cache") .. "/nixpkgs-maintainer.json.timestamp"

local M = {}
M.silent = false
M.cache_lifetime_days = nil
M._currently_refreshing = false
M._cached_file_is_recent = false
M._loaded_cache_is_recent = false
M._cached_maintainers = {}

local cache_file_exists = function()
    return vim.fn.filereadable(path_to_json) == 1
end

local log = function(message)
    if not M.silent then
        print("[cmp-nixpkgs-maintainers] " .. message)
    end
end

local refresh_cache = function()
    log("Refreshing maintainers list.")

    local on_exit = function(out)
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

        log("Finished downloading.")

        M._currently_refreshing = false
    end

    M._currently_refreshing = true
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
    )
end

local json_outdated = function()
    local cache_lifetime_s = M.cache_lifetime_days * (24 * 60 * 60)

    if vim.fn.filereadable(path_to_timestamp) == 0 then
        return false
    end

    local timestamp = vim.fn.readfile(path_to_timestamp)[1]

    local cache_age_s = os.difftime(os.time(), timestamp)
    return cache_age_s > cache_lifetime_s
end

M.refresh_cache_if_needed = function()
    if M._loaded_cache_is_recent or M._currently_refreshing then
        return
    end

    M._currently_refreshing = true

    if (not cache_file_exists()) or json_outdated() then
        refresh_cache()
    else
        M._currently_refreshing = false
    end
end

local load_cache_file = function()
    return vim.fn.json_decode(
        vim.fn.readfile(path_to_json)
    )
end

M.get_cached_maintainers = function(cache_lifetime_days)
    local cache_file_is_recent = not json_outdated()

    -- Read cache file in two cases:
    -- 1) Local cache is empty (we have not opened the cache file yet)
    -- 2) Local cache comes from an outdated cache file and the cache file has been refreshed
    local should_read_cache_file = (
        (M._cached_maintainers == {})
        or
        ((not M._loaded_cache_is_recent) and cache_file_is_recent)
    )

    if should_read_cache_file and cache_file_exists() then
        M._cached_maintainers = load_cache_file()

        -- Check if we have loaded a recent cache file
        M._loaded_cache_is_recent = cache_file_is_recent
    end

    return M._cached_maintainers
end

return M
