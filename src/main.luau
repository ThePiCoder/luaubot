local Info = {
    imgui = loadstring(game:HttpGet('https://github.com/depthso/Roblox-ImGUI/raw/main/ImGui.lua'))(),
    wsurl = "wss://gateway.discord.gg/?v=10&encoding=json",
    token = "",
    tojson = function(tbl) return game:GetService("HttpService"):JSONEncode(tbl) end,
    tolua = function(json) return game:GetService("HttpService"):JSONDecode(json) end
}

if not Info.imgui then
    warn("Failed to load ImGui module.")
    return
end

local Window = Info.imgui:CreateWindow({
    Title = "Output",
    Size = UDim2.new(0, 620, 0, 420),
    Position = UDim2.new(0.5, 0, 0, 70)
})
local ConsoleTab = Window:CreateTab({ Name = "Console" })
ConsoleTab:Separator({ Text = "Console" })
local Console = ConsoleTab:Console({
    Text = "<font color='rgb(245, 0, 245)'>[+] Successfully started console.</font>",
    ReadOnly = true,
    LineNumbers = true,
    Border = false,
    Fill = true,
    Enabled = true,
    AutoScroll = true,
    RichText = true,
    MaxLines = 20000
})

local ButtonRow = ConsoleTab:Row()
ButtonRow:Button({ Text = "Clear", Callback = Console.Clear })
ButtonRow:Button({ Text = "Pause", Callback = function(self)
    shared.Pause = not (shared.Pause or false)
    self.Text = shared.Pause and "Paused" or "Pause"
    Console.Enabled = not shared.Pause
end })
ButtonRow:Fill()

Window:ShowTab(ConsoleTab)

local Ws, Commands = nil, {}

function Commands:getcommand(content)
    return Commands[content:split(" ")[1]] or "not found"
end

function Commands:addCommand(name, func) Commands[name] = func end
function Commands:not1(tab) return table.concat(tab, " ", 2) end
function Commands:Output(message, r, g, b) Console:AppendText(`<font color="rgb(${r},${g},${b})">${message}</font>`) end

local Ops = {
    [10] = function(data)
        Console:AppendText("<font color='rgb(3, 252, 7)'>[+] Connected to Discord Gateway.</font>")
        Ws:Send(Info.tojson({
            op = 2,
            d = {
                token = Info.token,
                intents = 53608447,
                properties = { os = "linux", browser = "roblox", device = "roblox" }
            }
        }))
        Console:AppendText("<font color='rgb(3, 252, 7)'>[+] Payload sent.</font>")
    end,
    [0] = function(data)
        if data.t == "MESSAGE_CREATE" then
            local author, content = data.d.author, data.d.content
            local command = Commands:getcommand(content)
            if type(command) ~= "string" then command({ author = author, userId = author.id, username = author.username, content = Commands:not1(content:split(" ")) }) end
        end
    end
}

function Commands:Websocket(info)
    if info.token then Info.token = info.token end
    if not WebSocket then
        warn("WebSocket module is not loaded.")
        return
    end

    Ws = WebSocket.connect(Info.wsurl)
    Ws.OnMessage:Connect(function(message)
        local success, data = pcall(Info.tolua, message)
        if success and Ops[data.op] then
            Ops[data.op](data)
        else
            warn(`Failed to parse JSON: {message}`)
        end
    end)
    Ws.OnClose:Connect(function()
        Console:AppendText("<font color='rgb(194, 120, 17)'>[~] WebSocket closed. Restarting...</font>")
        Commands:Websocket(info)
    end)
    return Ws
end

Window:Center()
return Commands
