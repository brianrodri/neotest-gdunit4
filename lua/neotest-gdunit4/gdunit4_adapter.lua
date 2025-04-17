local vstest_connection = require("neotest-gdunit4.vstest_connection")
local utils = require("neotest-gdunit4.utils")
local processor = require("neotest-gdunit4.gdunit4_processor")
local tree_builder = require("neotest-gdunit4.gdunit4_tree")

local M = {}

-- GdUnit4 Adapter class
local GdUnit4Adapter = {}
GdUnit4Adapter.__index = GdUnit4Adapter

function GdUnit4Adapter.new(args)
    local self = setmetatable({}, GdUnit4Adapter)
    self.name = "gdunit4"
    self.host = args.host or "localhost"
    self.port = args.port or 31002
    self.connection = nil
    self.is_connected = false
    self.processor = processor.Processor.new()

    -- Create connection on init
    self:init()

    return self
end

function GdUnit4Adapter:init()
    self.connection = vstest_connection.VSTestConnection.new(self.host, self.port)

    -- Set up message handler
    self.connection.on_message = function(message)
        self.processor:handle_message(message)
    end

    self.connection.on_error = function(err)
        vim.notify("GdUnit4 error: " .. err, vim.log.levels.ERROR)
    end

    self.connection.on_close = function()
        self.is_connected = false
        vim.notify("Disconnected from GdUnit4 server", vim.log.levels.INFO)
    end

    -- Try to connect
    self.is_connected = self.connection:connect()
    if self.is_connected then
        vim.notify("Connected to GdUnit4 server", vim.log.levels.INFO)
    end

    -- Ensure we disconnect when Neovim exits
    vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
            self:disconnect()
        end,
    })
end

function GdUnit4Adapter:disconnect()
    if self.connection then
        self.connection:disconnect()
    end
end

-- NeoTest Adapter Interface Implementation

function GdUnit4Adapter:is_test_file(file_path)
    return utils.is_godot_test_file(file_path)
end

function GdUnit4Adapter:discover_positions(path)
    -- Ensure connection
    if not self.is_connected and not self.connection:connect() then
        return {}
    end

    -- Create request message
    local req_id = utils.generate_request_id()
    local request = {
        MessageType = "TestDiscovery.Start",
        RequestId = req_id,
        Sources = { path },
    }

    -- Create promise for the result
    local promise = utils.create_promise()
    self.processor.pending_requests[req_id] = {
        type = "discovery",
        resolve = promise.resolve,
    }

    -- Send the request
    self.connection:send_message(request)

    -- Wait for the result
    return promise.wait()
end

function GdUnit4Adapter:build_position(file_path)
    -- Build a position tree for the file
    local positions = self:discover_positions(file_path)

    -- Transform to NeoTest position tree
    return tree_builder.positions_to_tree(positions, file_path)
end

function GdUnit4Adapter:run(args)
    -- Check if we have tests to run
    if not args.tree then
        return {}
    end

    -- Ensure connection
    if not self.is_connected and not self.connection:connect() then
        return {}
    end

    -- Clear previous results
    self.processor.test_results = {}

    -- Extract test IDs to run
    local test_ids = {}
    for _, node in ipairs(args.tree:values()) do
        if node.type == "test" then
            table.insert(test_ids, node.id)
        end
    end

    -- Create request message
    local req_id = utils.generate_request_id()
    local request = {
        MessageType = "TestExecution.Start",
        RequestId = req_id,
        Tests = test_ids,
    }

    -- Create promise for the result
    local promise = utils.create_promise()
    self.processor.pending_requests[req_id] = {
        type = "execution",
        resolve = promise.resolve,
    }

    -- Send the request
    self.connection:send_message(request)

    -- Wait for the result
    return promise.wait()
end

function GdUnit4Adapter:attach_pos(_, result)
    return vim.tbl_extend("force", {}, result)
end

M.GdUnit4Adapter = GdUnit4Adapter

-- Create a new instance of the adapter
function M.get_adapter(args)
    return GdUnit4Adapter.new(args or {})
end

return M
