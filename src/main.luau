local HttpService = game:GetService("HttpService")

local bot = {}
bot.commands = {}

-- Function to send a POST request to the Node.js API
local function sendPostRequest(url, data, headers)
    local success, response = pcall(function()
        return HttpService:PostAsync(url, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson, false, headers)
    end)
    if not success then
        warn("Error sending POST request: " .. response)
        return nil
    else
        return HttpService:JSONDecode(response)
    end
end

-- Function to register a command
function bot:command(command, response)
    self.commands[command] = response
end

-- Function to run the bot
function bot:run(token)
    if not token then
        warn("No token provided. Exiting...")
        return
    end
    
    print("Starting bot...")

    -- Send a request to the Node.js server to connect to the Discord gateway
    local connectUrl = "http://localhost:3000/connect"
    local connectResponse = sendPostRequest(connectUrl, { token = token })

    if not connectResponse or connectResponse.error then
        print("Failed to connect to the Node.js API.")
        return
    end

    print("Connected to Node.js API successfully!")

    -- Monitor messages and check for commands
    local function onMessageReceived(data)
        if data.content then
            for command, response in pairs(self.commands) do
                if data.content:match("^" .. command) then
                    print("Command received: " .. command)
                    -- Call the response function for the command
                    print(response)
                end
            end
        end
    end

    -- Simulate message event for testing purposes
    onMessageReceived({ content = ".help" })  -- This would be triggered by the Node.js WebSocket in a real application
end

-- Extract token from the `run` method call and use it
local function extractTokenAndRun()
    -- Assuming the script is called with `bot:run("YOUR_TOKEN")`
    local token = debug.getupvalue(bot.run, 1)  -- Extract the first upvalue of the `run` method
    if token then
        bot:run(token)
    else
        warn("Failed to extract token.")
    end
end

-- Example of loading and running the script
-- Replace 'YOUR_TOKEN' with an actual token or retrieve it securely
bot:command(".help", "Here's a list of commands:\n.help - Shows this help message")
extractTokenAndRun()
