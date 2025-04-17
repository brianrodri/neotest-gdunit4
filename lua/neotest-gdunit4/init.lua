local M = {}

-- Setup function for the adapter
function M.setup(args)
    return require("neotest-gdunit4.gdunit4_adapter").get_adapter(args or {})
end

return M
