local user_config = vim.g.cmp_nixpkgs_maintainers_config or {}

local default_config = {
    debug = false,
    cache_lifetime_days = 14,

}

config = vim.tbl_deep_extend(
    "keep",
    user_config,
    default_config
)

return config
