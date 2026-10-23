-- Tiny static HTTP server for the offline PaperGames copy.
-- Runs on the bundled LuaJIT + LuaSocket in ./runtime.
-- Usage: runtime/luajit server.lua [port]

local SCRIPT = (arg and arg[0]) or "server.lua"
local BASE = SCRIPT:match("^(.*)/") or "."

package.path = BASE .. "/runtime/?.lua;" .. BASE .. "/runtime/?/init.lua;" .. package.path
package.cpath = BASE .. "/runtime/?.so;" .. BASE .. "/runtime/?/?.so;" .. package.cpath
local socket = require("socket")

local PORT = tonumber(arg and arg[1]) or 8080
local ROOT = BASE
local ACCESS = "/var/local/papergames-access.log"
local ERRORS = "/var/local/papergames-errors.log"

local MIME = {
    html = "text/html",
    js   = "application/javascript",
    css  = "text/css",
    json = "application/json",
    png  = "image/png",
    jpg  = "image/jpeg",
    jpeg = "image/jpeg",
    gif  = "image/gif",
    svg  = "image/svg+xml",
    ico  = "image/x-icon",
    woff2 = "font/woff2",
}

local function log(path, line)
    local f = io.open(path, "a")
    if f then
        f:write(os.date("%H:%M:%S"), " ", line, "\n")
        f:close()
    end
end

local function send_all(client, data)
    local i = 1
    while i <= #data do
        local last, err = client:send(data:sub(i))
        if not last then return false, err end
        i = last + 1
    end
    return true
end

local function handle(client)
    client:settimeout(3)
    local req = client:receive("*l")
    if not req then client:close(); return end

    while true do
        local line, err = client:receive("*l")
        if not line or line == "" then break end
        if err then break end
    end

    local method, target = req:match("^(%a+)%s+(%S+)")
    if not target then client:close(); return end

    local path = target:match("^[^?]*") or "/"
    local query = target:match("%?(.*)$") or ""

    if path == "/__err" then
        log(ERRORS, query)
        local gif = "GIF89a\1\0\1\0\128\0\0\0\0\0\255\255\255!\249\4\1\0\0\0\0,\0\0\0\0\1\0\1\0\0\2\2D\1\0;"
        send_all(client, "HTTP/1.0 200 OK\r\nContent-Type: image/gif\r\nContent-Length: " ..
            #gif .. "\r\nConnection: close\r\n\r\n" .. gif)
        client:close(); return
    end

    if path == "/" then path = "/index.html" end
    if path:find("%.%.", 1, false) then path = "/index.html" end

    local file = ROOT .. path
    local f = io.open(file, "rb")
    if not f then
        log(ACCESS, "404 " .. method .. " " .. path)
        send_all(client, "HTTP/1.0 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
        client:close(); return
    end

    local size = f:seek("end")
    f:seek("set", 0)
    local ext = path:match("%.([%w]+)$")
    local ct = MIME[(ext or ""):lower()] or "application/octet-stream"

    log(ACCESS, "200 " .. method .. " " .. path)
    send_all(client, "HTTP/1.0 200 OK\r\nContent-Type: " .. ct ..
        "\r\nContent-Length: " .. size ..
        "\r\nConnection: close\r\nCache-Control: no-cache\r\n\r\n")

    if method ~= "HEAD" then
        while true do
            local chunk = f:read(65536)
            if not chunk then break end
            local ok = send_all(client, chunk)
            if not ok then break end
        end
    end
    f:close()
    client:close()
end

local server, err = socket.bind("127.0.0.1", PORT, 64)
if not server then
    io.stderr:write("bind failed: " .. tostring(err) .. "\n")
    os.exit(1)
end
server:settimeout(0.5)

while true do
    local client = server:accept()
    if client then
        local ok, e = pcall(handle, client)
        if not ok then
            pcall(function() client:close() end)
            log(ERRORS, "SERVER " .. tostring(e))
        end
    end
end
