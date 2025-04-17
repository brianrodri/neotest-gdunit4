local Path = require("plenary.path")
local async = require("neotest.async")

local M = {}

-- Map VSTest status to NeoTest status
function M.map_status(outcome)
    local status_map = {
        Passed = "passed",
        Failed = "failed",
        Skipped = "skipped",
        NotFound = "skipped",
    }

    return status_map[outcome] or "failed"
end

-- Extract line number from stack trace
function M.extract_line_from_stacktrace(stacktrace)
    -- Implementation depends on Godot's stack trace format
    local line = stacktrace:match("line (%d+)")
    return line and tonumber(line) or nil
end

-- Generate a unique request ID
function M.generate_request_id()
    return tostring(os.time()) .. tostring(math.random(1000, 9999))
end

-- Create a promise for async operations
function M.create_promise()
    local promise = {}
    promise.resolved = false

    promise.resolve = function(value)
        promise.value = value
        promise.resolved = true
        if promise.callback then
            promise.callback(value)
        end
    end

    promise.wait = function()
        while not promise.resolved do
            async.sleep(10)
        end
        return promise.value
    end

    return promise
end

-- Check if file is a Godot test file
function M.is_godot_test_file(file_path)
    local file = Path:new(file_path)

    -- Only consider .gd files
    if file:extension() ~= "gd" then
        return false
    end

    -- Check filename pattern for test files
    if file:filename():match("_test%.gd$") or file:filename():match("test_.*%.gd$") then
        return true
    end

    -- Check file content for GdUnit4 annotations
    local content = require("neotest.lib").files.read(file_path)
    return content:match("@TestSuite") ~= nil
end

return M
