local tcp = require("neotest-gdunit4.tcp_connection")
local M = {}

-- VSTest Connection class
local VSTestConnection = {}
VSTestConnection.__index = VSTestConnection

function VSTestConnection.new(host, port)
    local self = setmetatable({}, VSTestConnection)
    self.tcp = tcp.TCPConnection.new(host, port)
    self.buffer = ""
    self.on_message = nil
    self.on_error = nil
    self.on_close = nil

    -- Set up TCP connection callbacks
    self.tcp.on_data = function(data)
        self:handle_data(data)
    end

    self.tcp.on_error = function(err)
        if self.on_error then
            self.on_error(err)
        end
    end

    self.tcp.on_close = function()
        if self.on_close then
            self.on_close()
        end
    end

    return self
end

-- Function to encode integer as 7-bit
function VSTestConnection:encode_7bit_int(value)
    local result = ""

    repeat
        local byte_val = value % 128
        value = math.floor(value / 128)

        if value > 0 then
            byte_val = byte_val + 128 -- Set the high bit
        end

        result = result .. string.char(byte_val)
    until value == 0

    return result
end

-- Function to decode 7-bit encoded integer
function VSTestConnection:decode_7bit_int(bytes, start_pos)
    local result = 0
    local shift = 0
    local pos = start_pos or 1
    local byte_val

    repeat
        if pos > #bytes then
            return nil, pos -- Not enough data
        end

        byte_val = bytes:byte(pos)
        result = result + bit.band(byte_val, 0x7F) * (2 ^ shift)
        shift = shift + 7
        pos = pos + 1
    until bit.band(byte_val, 0x80) == 0

    return result, pos
end

-- Handle incoming data with 7-bit size prefix
function VSTestConnection:handle_data(data)
    -- Append new data to existing buffer
    self.buffer = self.buffer .. data

    -- Process complete messages in the buffer
    while #self.buffer > 0 do
        -- Try to decode the size prefix
        local size, next_pos = self:decode_7bit_int(self.buffer)

        -- If we couldn't decode a complete size, wait for more data
        if not size then
            break
        end

        -- Check if we have enough data for the complete message
        if #self.buffer < next_pos + size - 1 then
            break -- Wait for more data
        end

        -- Extract the JSON payload
        local json_data = self.buffer:sub(next_pos, next_pos + size - 1)

        -- Remove the processed message from the buffer
        self.buffer = self.buffer:sub(next_pos + size)

        -- Process the JSON payload
        vim.schedule(function()
            local success, parsed_data = pcall(vim.json.decode, json_data)

            if not success then
                if self.on_error then
                    self.on_error("Failed to parse JSON data: " .. json_data:sub(1, 100))
                end
                return
            end

            if self.on_message then
                self.on_message(parsed_data)
            end
        end)
    end
end

-- Send a message with proper encoding
function VSTestConnection:send_message(message)
    local json_data

    if type(message) == "string" then
        json_data = message
    else
        local success, encoded = pcall(vim.json.encode, message)
        if not success then
            if self.on_error then
                self.on_error("Failed to encode message to JSON")
            end
            return false
        end
        json_data = encoded
    end

    -- Calculate the size of the data
    local size = #json_data

    -- Encode the size as 7-bit
    local size_prefix = self:encode_7bit_int(size)

    -- Send the size-prefixed data
    return self.tcp:write(size_prefix .. json_data)
end

function VSTestConnection:connect()
    return self.tcp:connect()
end

function VSTestConnection:disconnect()
    self.tcp:disconnect()
end

M.VSTestConnection = VSTestConnection
return M
