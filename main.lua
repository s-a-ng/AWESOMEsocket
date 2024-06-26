if not GlobalConnections then
    getgenv().GlobalConnections = {}
end

local SERVER = "https://plaintivegroundedrar.ngrokadaxdlolol.repl.co"

local HttpService = game:GetService("HttpService")
local Connection = {}
Connection.__index = Connection

local Events = {}

local MessageRecord = {}

local ID_TO_CONNECTION = {}

local STATUS_CODES = {
    ["404"] = "Not found",
}

local function HandleEvents(Events, ConnectionId)
    local Connection = ID_TO_CONNECTION[ConnectionId]
    for _, Event in pairs(Events) do
        if Event.Type == "Message" then
            Connection.Events.OnMessage:Fire(Event.Data)
        elseif Event.Type == "ConnectionClosed" then
            Connection.Events.OnClose:Fire()
            Connection.Alive = false
        end
    end
end

function UpdateEventQueue(ConnectionId)
    local Connection = ID_TO_CONNECTION[ConnectionId]
    
    while Connection.Alive do
        local Status, Recieved = pcall(function()
            return game:HttpPost(SERVER .. "/queue", HttpService:JSONEncode({ConnectionId = ConnectionId}))
        end)
        
        if STATUS_CODES[Recieved] or not Status then 
            return
        end
        warn(Recieved)
        Recieved = HttpService:JSONDecode(Recieved)
        HandleEvents(Recieved)
        task.wait()
    end
end

function Initialize(ConnectionId, URL)
    return game:HttpPost(SERVER .. "/initalize", HttpService:JSONEncode({
        ConnectionId = ConnectionId,
        URL = URL,
    }))
end



function Connection.connect(url)
    local self = setmetatable({}, Connection)
    self.ConnectionId = HttpService:GenerateGUID(false)
    self.Url = url
    self.Alive = true
    
    if Initialize(self.ConnectionId, url) ~= "OK" then 
        return 
    end 
    
    table.insert(GlobalConnections, self)
    ID_TO_CONNECTION[self.ConnectionId] = self

    self.Events = {
        OnClose = Instance.new("BindableEvent"),
        OnMessage = Instance.new("BindableEvent"),
    }

    self.OnClose = self.Events.OnClose.Event
    self.OnMessage = self.Events.OnMessage.Event

    coroutine.wrap(UpdateEventQueue)(self.ConnectionId)
    
    return self
end

function Connection:Send(data)
    game:HttpPost(SERVER .. "/send", HttpService:JSONEncode({
        ConnectionId = self.ConnectionId,
        Data = data
    }))
end

function Connection:Close()
    game:HttpPost(SERVER .. "/close", HttpService:JSONEncode({
        ConnectionId = self.ConnectionId,
    }))
end

game.Close:Connect(function()
    for _, SomeConnection in ipairs(GlobalConnections) do
        SomeConnection:Close()
    end
end)

return Connection
