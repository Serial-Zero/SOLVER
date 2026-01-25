local players = game:GetService("Players")
local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local camera = workspace.CurrentCamera
local espItems = {}

local function getCamera()
    if not camera or not camera.Parent then
        camera = workspace.CurrentCamera
    end
    return camera
end

local function destroyDrawing(d)
    if d and d.Remove then
        d:Remove()
    end
end

local function hideItem(item)
    if not item then return end
    if item.box then item.box.Visible = false end
    if item.tracer then item.tracer.Visible = false end
    if item.nameText then item.nameText.Visible = false end
    if item.distanceText then item.distanceText.Visible = false end
    if item.healthText then item.healthText.Visible = false end
end

local function clearEsp(plr)
    local item = espItems[plr]
    if item then
        if item.conn then
            item.conn:Disconnect()
        end
        destroyDrawing(item.box)
        destroyDrawing(item.tracer)
        destroyDrawing(item.nameText)
        destroyDrawing(item.distanceText)
        destroyDrawing(item.healthText)
        espItems[plr] = nil
    end
end

local function clearAllEsp()
    for plr in pairs(espItems) do
        clearEsp(plr)
    end
end

local function newText(color)
    local t = Drawing.new("Text")
    t.Center = true
    t.Outline = true
    t.Size = 13
    t.Color = color
    t.Visible = false
    return t
end

local function newBox(color)
    local b = Drawing.new("Square")
    b.Filled = false
    b.Thickness = 1
    b.Color = color
    b.Visible = false
    return b
end

local function newLine(color)
    local l = Drawing.new("Line")
    l.Thickness = 1
    l.Color = color
    l.Visible = false
    return l
end

local function ensureEsp(plr)
    if espItems[plr] then return espItems[plr] end
    if not Drawing or not Drawing.new then return nil end
    local color = Color3.fromRGB(255, 80, 80)
    local item = {
        box = newBox(color),
        tracer = newLine(color),
        nameText = newText(color),
        distanceText = newText(color),
        healthText = newText(color)
    }
    item.conn = plr.CharacterAdded:Connect(function()
        hideItem(item)
    end)
    espItems[plr] = item
    return item
end

local function getChar(plr)
    return plr and plr.Character or nil
end

local function getHumanoid(char)
    return char and char:FindFirstChildOfClass("Humanoid") or nil
end

local function updateEspForPlayer(plr, settings)
    local item = ensureEsp(plr)
    if not item then return end
    if not settings.espEnabled then
        hideItem(item)
        return
    end
    local char = getChar(plr)
    if not char then
        hideItem(item)
        return
    end
    local cam = getCamera()
    if not cam then
        hideItem(item)
        return
    end
    local cf, size = char:GetBoundingBox()
    local top = cam:WorldToViewportPoint(cf.Position + Vector3.new(0, size.Y / 2, 0))
    local bottom = cam:WorldToViewportPoint(cf.Position - Vector3.new(0, size.Y / 2, 0))
    if top.Z <= 0 or bottom.Z <= 0 then
        hideItem(item)
        return
    end
    local height = math.abs(top.Y - bottom.Y)
    local width = height * (size.X / size.Y)
    local x = top.X - width / 2
    local y = top.Y
    if settings.espBoxes then
        item.box.Size = Vector2.new(width, height)
        item.box.Position = Vector2.new(x, y)
        item.box.Visible = true
    else
        item.box.Visible = false
    end
    if settings.espTracers then
        local vp = cam.ViewportSize
        item.tracer.From = Vector2.new(vp.X / 2, vp.Y)
        item.tracer.To = Vector2.new(top.X, bottom.Y)
        item.tracer.Visible = true
    else
        item.tracer.Visible = false
    end
    if settings.espNames then
        item.nameText.Text = plr.Name
        item.nameText.Position = Vector2.new(top.X, y - 14)
        item.nameText.Visible = true
    else
        item.nameText.Visible = false
    end
    if settings.espDistance then
        local dist = (cam.CFrame.Position - cf.Position).Magnitude
        item.distanceText.Text = tostring(math.floor(dist)) .. " studs"
        item.distanceText.Position = Vector2.new(top.X, bottom.Y + 2)
        item.distanceText.Visible = true
    else
        item.distanceText.Visible = false
    end
    if settings.espHealth then
        local hum = getHumanoid(char)
        if hum and hum.MaxHealth > 0 then
            local hp = math.floor((hum.Health / hum.MaxHealth) * 100)
            item.healthText.Text = tostring(hp) .. "%"
            item.healthText.Position = Vector2.new(top.X + width / 2 + 18, y)
            item.healthText.Visible = true
        else
            item.healthText.Visible = false
        end
    else
        item.healthText.Visible = false
    end
end

local function updateAllEsp(settings)
    for _, plr in ipairs(players:GetPlayers()) do
        if plr ~= players.LocalPlayer then
            updateEspForPlayer(plr, settings)
        end
    end
end

local function createEsp(plr)
    if plr and plr ~= players.LocalPlayer then
        ensureEsp(plr)
    end
end

local espConn
local function startEspLoop(settings)
    if espConn then
        espConn:Disconnect()
    end
    espConn = runService.RenderStepped:Connect(function()
        updateAllEsp(settings)
    end)
end

local function normalizeSettings(settings)
    if type(settings) ~= "table" then
        settings = {}
    end
    if settings.isTransparent == nil then
        settings.isTransparent = true
    end
    if type(settings.theme) ~= "string" or settings.theme == "" or settings.theme == "default" then
        settings.theme = "Dark"
    end
    if settings.espEnabled == nil then
        settings.espEnabled = false
    end
    if settings.espBoxes == nil then
        settings.espBoxes = true
    end
    if settings.espTracers == nil then
        settings.espTracers = false
    end
    if settings.espNames == nil then
        settings.espNames = true
    end
    if settings.espDistance == nil then
        settings.espDistance = true
    end
    if settings.espHealth == nil then
        settings.espHealth = true
    end
    return settings
end

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/DeadSignalFound/SOLVER/refs/heads/main/UI/main.lua"))()
local settings = normalizeSettings(loadstring(game:HttpGet("https://raw.githubusercontent.com/DeadSignalFound/SOLVER/refs/heads/main/scripts/Settings.lua"))())

local Window = WindUI:CreateWindow({
    Title = "SOLVER",
    Icon = "door-open",
    Author = "by DeadSignalFound",
    Folder = "SOLVER",
    

    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    Transparent = settings.isTransparent,
    Theme = settings.theme,
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    

    User = {
        Enabled = true,
        Anonymous = true,
        Callback = function()
            print("clicked")
        end,
    },
    
})

local visualTab = Window:Tab({
    Title = "Visual",
    Icon = "eye"
})

local settingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})

visualTab:Toggle({
    Title = "ESP Enabled",
    Desc = "Main ESP",
    Value = settings.espEnabled,
    Callback = function(val)
        settings.espEnabled = val
        if not val then
            clearAllEsp()
        end
    end
})

visualTab:Toggle({
    Title = "ESP Boxes",
    Desc = "Box around player",
    Value = settings.espBoxes,
    Callback = function(val)
        settings.espBoxes = val
    end
})

visualTab:Toggle({
    Title = "ESP Tracers",
    Desc = "Line to player",
    Value = settings.espTracers,
    Callback = function(val)
        settings.espTracers = val
    end
})

visualTab:Toggle({
    Title = "ESP Names",
    Desc = "Show player name",
    Value = settings.espNames,
    Callback = function(val)
        settings.espNames = val
    end
})

visualTab:Toggle({
    Title = "ESP Distance",
    Desc = "Show distance",
    Value = settings.espDistance,
    Callback = function(val)
        settings.espDistance = val
    end
})

visualTab:Toggle({
    Title = "ESP Health",
    Desc = "Show health",
    Value = settings.espHealth,
    Callback = function(val)
        settings.espHealth = val
    end
})

players.PlayerRemoving:Connect(function(plr)
    clearEsp(plr)
end)

startEspLoop(settings)

local themeList = {}
local themes = WindUI:GetThemes()
for k in next, themes do
    themeList[#themeList + 1] = k
end
table.sort(themeList)

if not themes[settings.theme] then
    settings.theme = "Dark"
end

local themeDropdown = settingsTab:Dropdown({
    Title = "Theme",
    Desc = "Select UI theme",
    Values = themeList,
    Value = settings.theme,
    Multi = false,
    AllowNone = false,
    Callback = function(opt)
        local sel = opt
        if type(sel) == "table" then
            sel = sel[1]
        end
        if type(sel) ~= "string" then
            return
        end
        settings.theme = sel
        WindUI:SetTheme(sel)
    end
})

themeDropdown:Select(settings.theme)