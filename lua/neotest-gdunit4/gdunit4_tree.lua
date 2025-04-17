local Path = require("plenary.path")

local M = {}

-- Build a position tree for the file
function M.positions_to_tree(positions, root_path)
    local root = {
        type = "file",
        path = root_path,
        name = Path:new(root_path):filename(),
        children = {},
    }

    for _, pos in pairs(positions) do
        if pos.path == root_path then
            table.insert(root.children, {
                type = "test",
                path = root_path,
                name = pos.name,
                range = pos.range,
                id = pos.id,
            })
        end
    end

    return root
end

return M
