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
    if type(d) == "table" then
        for _, v in pairs(d) do
            destroyDrawing(v)
        end
        return
    end
    if d and d.Remove then
        d:Remove()
    end
end

local function setVisible(d, v)
    if type(d) == "table" then
        for _, o in pairs(d) do
            if o then o.Visible = v end
        end
        return
    end
    if d then d.Visible = v end
end

local function hideItem(item)
    if not item then return end
    setVisible(item.box, false)
    setVisible(item.boxOutline, false)
    setVisible(item.fill, false)
    setVisible(item.corners, false)
    setVisible(item.tracer, false)
    setVisible(item.nameText, false)
    setVisible(item.distanceText, false)
    setVisible(item.healthText, false)
    setVisible(item.healthBar, false)
    setVisible(item.healthBarOutline, false)
end

local function clearEsp(plr)
    local item = espItems[plr]
    if item then
        if item.conn then
            item.conn:Disconnect()
        end
        destroyDrawing(item.box)
        destroyDrawing(item.boxOutline)
        destroyDrawing(item.fill)
        destroyDrawing(item.corners)
        destroyDrawing(item.tracer)
        destroyDrawing(item.nameText)
        destroyDrawing(item.distanceText)
        destroyDrawing(item.healthText)
        destroyDrawing(item.healthBar)
        destroyDrawing(item.healthBarOutline)
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

local function newFill(color)
    local b = Drawing.new("Square")
    b.Filled = true
    b.Thickness = 1
    b.Color = color
    b.Transparency = 0.85
    b.Visible = false
    return b
end

local function newCornerLines(color)
    local lines = {}
    for i = 1, 8 do
        lines[i] = newLine(color)
    end
    return lines
end

local function setCornerLines(lines, x, y, w, h, color, thick, alpha)
    if not lines then return end
    local len = math.max(6, math.min(w, h) * 0.25)
    local x2 = x + w
    local y2 = y + h
    for _, ln in ipairs(lines) do
        ln.Color = color
        ln.Thickness = thick
        ln.Transparency = alpha
        ln.Visible = true
    end
    lines[1].From = Vector2.new(x, y)
    lines[1].To = Vector2.new(x + len, y)
    lines[2].From = Vector2.new(x, y)
    lines[2].To = Vector2.new(x, y + len)
    lines[3].From = Vector2.new(x2 - len, y)
    lines[3].To = Vector2.new(x2, y)
    lines[4].From = Vector2.new(x2, y)
    lines[4].To = Vector2.new(x2, y + len)
    lines[5].From = Vector2.new(x, y2)
    lines[5].To = Vector2.new(x + len, y2)
    lines[6].From = Vector2.new(x, y2 - len)
    lines[6].To = Vector2.new(x, y2)
    lines[7].From = Vector2.new(x2 - len, y2)
    lines[7].To = Vector2.new(x2, y2)
    lines[8].From = Vector2.new(x2, y2 - len)
    lines[8].To = Vector2.new(x2, y2)
end

local function ensureEsp(plr)
    if espItems[plr] then return espItems[plr] end
    if not Drawing or not Drawing.new then return nil end
    local color = Color3.fromRGB(255, 80, 80)
    local item = {
        box = newBox(color),
        boxOutline = newBox(Color3.new(0, 0, 0)),
        fill = newFill(color),
        corners = newCornerLines(color),
        tracer = newLine(color),
        nameText = newText(color),
        distanceText = newText(color),
        healthText = newText(color),
        healthBar = newLine(color),
        healthBarOutline = newLine(Color3.new(0, 0, 0))
    }
    item.healthBar.Thickness = 2
    item.healthBarOutline.Thickness = 4
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
    if height <= 0 or width <= 0 then
        hideItem(item)
        return
    end
    local x = top.X - width / 2
    local y = top.Y
    local color = Color3.fromRGB(255, 80, 80)
    if settings.espRainbow then
        local hue = (os.clock() * 0.15) % 1
        color = Color3.fromHSV(hue, 1, 1)
    end
    local alpha = 1
    local thick = 1
    if settings.espPulse then
        local t = os.clock() * 3
        local p = (math.sin(t) + 1) * 0.5
        alpha = 0.55 + p * 0.45
        thick = 1 + p * 1.5
    end
    local style = settings.espStyle
    if style ~= "Corner" and style ~= "Box" then
        style = "Box"
    end
    if settings.espBoxes then
        if style == "Corner" then
            setVisible(item.box, false)
            setVisible(item.boxOutline, false)
            setVisible(item.fill, false)
            setCornerLines(item.corners, x, y, width, height, color, thick, alpha)
        else
            setVisible(item.corners, false)
            if settings.espFill then
                item.fill.Size = Vector2.new(width, height)
                item.fill.Position = Vector2.new(x, y)
                item.fill.Color = color
                item.fill.Transparency = 0.85 * alpha
                item.fill.Visible = true
            else
                item.fill.Visible = false
            end
            if settings.espOutline then
                item.boxOutline.Size = Vector2.new(width + 2, height + 2)
                item.boxOutline.Position = Vector2.new(x - 1, y - 1)
                item.boxOutline.Color = Color3.new(0, 0, 0)
                item.boxOutline.Thickness = thick + 2
                item.boxOutline.Transparency = alpha
                item.boxOutline.Visible = true
            else
                item.boxOutline.Visible = false
            end
            item.box.Size = Vector2.new(width, height)
            item.box.Position = Vector2.new(x, y)
            item.box.Color = color
            item.box.Thickness = thick
            item.box.Transparency = alpha
            item.box.Visible = true
        end
    else
        setVisible(item.box, false)
        setVisible(item.boxOutline, false)
        setVisible(item.fill, false)
        setVisible(item.corners, false)
    end
    if settings.espTracers then
        local vp = cam.ViewportSize
        item.tracer.From = Vector2.new(vp.X / 2, vp.Y)
        item.tracer.To = Vector2.new(top.X, bottom.Y)
        item.tracer.Color = color
        item.tracer.Thickness = thick
        item.tracer.Transparency = alpha
        item.tracer.Visible = true
    else
        item.tracer.Visible = false
    end
    if settings.espNames then
        local name = plr.DisplayName
        if not name or name == "" then
            name = plr.Name
        end
        item.nameText.Text = name
        item.nameText.Position = Vector2.new(top.X, y - 14)
        item.nameText.Color = color
        item.nameText.Transparency = alpha
        item.nameText.Visible = true
    else
        item.nameText.Visible = false
    end
    if settings.espDistance then
        local dist = (cam.CFrame.Position - cf.Position).Magnitude
        item.distanceText.Text = tostring(math.floor(dist)) .. " studs"
        item.distanceText.Position = Vector2.new(top.X, bottom.Y + 2)
        item.distanceText.Color = color
        item.distanceText.Transparency = alpha
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
            item.healthText.Color = color
            item.healthText.Transparency = alpha
            item.healthText.Visible = true
        else
            item.healthText.Visible = false
        end
    else
        item.healthText.Visible = false
    end
    if settings.espHealthBar then
        local hum = getHumanoid(char)
        if hum and hum.MaxHealth > 0 then
            local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local barColor = Color3.fromRGB(255 * (1 - hp), 255 * hp, 0)
            local barX = x - 6
            item.healthBarOutline.From = Vector2.new(barX, y)
            item.healthBarOutline.To = Vector2.new(barX, y + height)
            item.healthBarOutline.Transparency = alpha
            item.healthBarOutline.Visible = true
            item.healthBar.From = Vector2.new(barX, y + height)
            item.healthBar.To = Vector2.new(barX, y + height - (height * hp))
            item.healthBar.Color = barColor
            item.healthBar.Transparency = alpha
            item.healthBar.Visible = true
        else
            item.healthBar.Visible = false
            item.healthBarOutline.Visible = false
        end
    else
        item.healthBar.Visible = false
        item.healthBarOutline.Visible = false
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
    if settings.espHealthBar == nil then
        settings.espHealthBar = true
    end
    if settings.espStyle ~= "Corner" and settings.espStyle ~= "Box" then
        settings.espStyle = "Corner"
    end
    if settings.espRainbow == nil then
        settings.espRainbow = false
    end
    if settings.espPulse == nil then
        settings.espPulse = false
    end
    if settings.espFill == nil then
        settings.espFill = false
    end
    if settings.espOutline == nil then
        settings.espOutline = true
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

local styleDropdown = visualTab:Dropdown({
    Title = "ESP Style",
    Desc = "Box or corner",
    Values = { "Box", "Corner" },
    Value = settings.espStyle,
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
        settings.espStyle = sel
    end
})

styleDropdown:Select(settings.espStyle)

visualTab:Toggle({
    Title = "ESP Boxes",
    Desc = "Box around player",
    Value = settings.espBoxes,
    Callback = function(val)
        settings.espBoxes = val
    end
})

visualTab:Toggle({
    Title = "ESP Outline",
    Desc = "Outline for boxes",
    Value = settings.espOutline,
    Callback = function(val)
        settings.espOutline = val
    end
})

visualTab:Toggle({
    Title = "ESP Fill",
    Desc = "Filled box",
    Value = settings.espFill,
    Callback = function(val)
        settings.espFill = val
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

visualTab:Toggle({
    Title = "ESP Health Bar",
    Desc = "Health bar",
    Value = settings.espHealthBar,
    Callback = function(val)
        settings.espHealthBar = val
    end
})

visualTab:Toggle({
    Title = "ESP Rainbow",
    Desc = "Rainbow colors",
    Value = settings.espRainbow,
    Callback = function(val)
        settings.espRainbow = val
    end
})

visualTab:Toggle({
    Title = "ESP Pulse",
    Desc = "Pulse effect",
    Value = settings.espPulse,
    Callback = function(val)
        settings.espPulse = val
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