local utils = require("neotest-gdunit4.utils")

local M = {}

local Processor = {}
Processor.__index = Processor

function Processor.new()
    local self = setmetatable({}, Processor)
    self.discovered_tests = {}
    self.test_results = {}
    self.pending_requests = {}
    return self
end

-- Process test discovery result
function Processor:process_test_found(message)
    local test = message.Test
    if not test or not test.FullyQualifiedName then
        return
    end

    -- Store the test in our discovered tests
    self.discovered_tests[test.FullyQualifiedName] = {
        id = test.FullyQualifiedName,
        name = test.DisplayName or test.FullyQualifiedName,
        path = test.Source,
        range = test.LineNumber and {
            start = { line = test.LineNumber },
            ["end"] = { line = test.LineNumber },
        } or nil,
    }
end

-- Process discovery completion
function Processor:process_discovery_completed(message)
    local req_id = message.RequestId
    local request = self.pending_requests[req_id]

    if request and request.type == "discovery" then
        request.resolve(self.discovered_tests)
        self.pending_requests[req_id] = nil
    end
end

-- Process test result
function Processor:process_test_result(message)
    local result = message.TestResult
    if not result or not result.TestCase then
        return
    end

    local test_id = result.TestCase.FullyQualifiedName

    self.test_results[test_id] = {
        status = utils.map_status(result.Outcome),
        output = result.Messages and table.concat(result.Messages, "\n") or "",
        short = result.ErrorMessage,
        errors = result.ErrorMessage
                and {
                    {
                        message = result.ErrorMessage,
                        line = result.ErrorStackTrace and utils.extract_line_from_stacktrace(result.ErrorStackTrace)
                            or nil,
                    },
                }
            or nil,
    }
end

-- Process execution completion
function Processor:process_execution_completed(message)
    local req_id = message.RequestId
    local request = self.pending_requests[req_id]

    if request and request.type == "execution" then
        request.resolve(self.test_results)
        self.pending_requests[req_id] = nil
    end
end

-- Handle VSTest messages
function Processor:handle_message(message)
    if message.MessageType == "TestDiscovery.TestFound" then
        -- Store discovered test
        self:process_test_found(message)
    elseif message.MessageType == "TestDiscovery.Completed" then
        -- Notify discovery completion
        self:process_discovery_completed(message)
    elseif message.MessageType == "TestExecution.TestResult" then
        -- Process test result
        self:process_test_result(message)
    elseif message.MessageType == "TestExecution.Completed" then
        -- Process test run completion
        self:process_execution_completed(message)
    elseif message.MessageType == "TestSession.Message" then
        -- Handle diagnostic messages
        vim.notify("GdUnit4 server: " .. message.Message, vim.log.levels.INFO)
    end
end

M.Processor = Processor
return M
