local Info = {
    imgui = loadstring(game:HttpGet('https://github.com/depthso/Roblox-ImGUI/raw/main/ImGui.lua'))(),
    wsurl = "wss://gateway.discord.gg/?v=10&encoding=json",
    token = "",
    tojson = game.GetService("HttpService").JSONEncode,
    tolua = game.GetService("HttpService").JSONDecode,
}

local Window = Info.imgui:CreateWindow({
    Title = "Output",
    Size = UDim2.new(0, 620, 0, 420),
    Position = UDim2.new(0.5, 0, 0, 70)
})
local ConsoleTab = Window:CreateTab({ Name = "Console" })
local Console = ConsoleTab:Console({
    Text = `<font color="rgb(245, 0, 245)">[+] Successfully started console.</font>`,
    ReadOnly = true, LineNumbers = true, Border = false, Fill = true, Enabled = true,
    AutoScroll = true, RichText = true, MaxLines = 20000,
})
ConsoleTab:Row():Button({ Text = "Clear", Callback = Console.Clear })
ConsoleTab:Row():Button({ Text = "Pause", Callback = function(self)
    shared.Pause = not shared.Pause
    self.Text = shared.Pause and "Paused" or "Pause"
    Console.Enabled = not shared.Pause
end })
Window:ShowTab(ConsoleTab)

local Ws, Commands = nil, {}

function Commands:getcommand(content) return Commands[content:split(" ")[1]:lower()] or "not found" end
function Commands:addCommand(name, func, opts)
    opts = opts or {}
    Commands[name] = { func = func, cooldown = opts.cooldown or 0, lastUsed = 0, aliases = opts.aliases or {} }
    for _, alias in ipairs(Commands[name].aliases) do Commands[alias] = Commands[name] end
end
function Commands:isCooldownActive(name) return Commands[name] and tick() - Commands[name].lastUsed < Commands[name].cooldown end
function Commands:Output(msg, r, g, b) pcall(function() Console:AppendText(`<font color="rgb({r},{g},{b})">{msg}</font>`) end) end
function Commands:handleError(err, info) self:Output(`<font color="rgb(255,0,0)">[ERROR]: ${err}</font>` .. (info and `<font color="rgb(255,165,0)"> [INFO]: ${info}</font>` or ""), 255, 0, 0) end

local Ops = {
    [10] = function() pcall(function() Console:AppendText("<font color='rgb(3,252,7)'>[+] Connected to Discord Gateway.</font>") Ws:Send(Info.tojson({op = 2, d = {token = Info.token, intents = 53608447, properties = {os = "linux", browser = "roblox", device = "roblox"}})) end),
    [0] = function(data)
        if data.t == "MESSAGE_CREATE" then
            Commands:executeCommand({author = data.d.author, userId = data.d.author.id, username = data.d.author.username, content = data.d.content})
        end
    end
}

function Commands:executeCommand(cmdData)
    local cmd = self:getcommand(cmdData.content)
    if cmd == "not found" then self:Output(`Command '${cmdData.content}' not found.`, 255, 0, 0) elseif self:isCooldownActive(cmdData.content) then self:Output("Command on cooldown. Please wait.", 255, 165, 0) else
        pcall(function() cmd.func({author = cmdData.author, userId = cmdData.userId, username = cmdData.username, content = table.concat({select(2, cmdData.content:split(" "))}, " ")}) cmd.lastUsed = tick() end, function(err) self:handleError("Error executing command.", err) end)
    end
end

function Commands:Websocket(info)
    if info.token then Info.token = info.token end
    Ws = WebSocket.connect(Info.wsurl)
    Ws.OnMessage:Connect(function(msg)
        local success, data = pcall(Info.tolist, msg)
        if not success then self:handleError("Failed to parse JSON message.", msg) return end
        if Ops[data.op] then pcall(function() Ops[data.op](data) end, function(err) self:handleError("Error processing operation.", err) end) else self:handleError("Unhandled op code.", data.op) end
    end)
    Ws.OnClose:Connect(function() pcall(function() Console:AppendText("<font color='rgb(194,120,17)'>[~] Websocket closed, restarting...</font>") self:Websocket(info) end, function(err) self:handleError("WebSocket closed unexpectedly.", err) end) end)
    return Ws
end

return Commands
