local M = {}

-- TCP Connection class
local TCPConnection = {}
TCPConnection.__index = TCPConnection

function TCPConnection.new(host, port)
    local self = setmetatable({}, TCPConnection)
    self.host = host or "localhost"
    self.port = port or 0
    self.socket = vim.loop.new_tcp()
    self.connected = false
    self.buffer = ""
    self.on_data = nil
    self.on_error = nil
    self.on_close = nil
    return self
end

function TCPConnection:connect()
    if self.connected then
        return true
    end

    local success, err = self.socket:connect(self.host, self.port)
    if not success then
        if self.on_error then
            self.on_error("Failed to connect: " .. (err or "unknown error"))
        end
        return false
    end

    self.connected = true

    -- Set up reading callback
    self.socket:read_start(function(read_err, data)
        if read_err then
            if self.on_error then
                self.on_error("Read error: " .. read_err)
            end
            self:disconnect()
            return
        end

        if data then
            -- Process received data
            if self.on_data then
                self.on_data(data)
            end
        else
            -- EOF received, connection closed
            self:disconnect()
        end
    end)

    return true
end

function TCPConnection:disconnect()
    if not self.connected then
        return
    end

    self.socket:read_stop()
    self.socket:close()
    self.connected = false

    if self.on_close then
        self.on_close()
    end
end

function TCPConnection:write(data, callback)
    if not self.connected and not self:connect() then
        return false
    end

    self.socket:write(data, function(err)
        if err then
            if self.on_error then
                self.on_error("Write error: " .. err)
            end
            self:disconnect()
        elseif callback then
            callback()
        end
    end)

    return true
end

M.TCPConnection = TCPConnection
return M
