local players = game:GetService("Players")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local workspace = game:GetService("Workspace")
local camera = workspace.CurrentCamera
local espItems = {}
local espSettings = {
    espEnabled = false,
    espBoxes = false,
    espTracers = false,
    espNames = false,
    espDistance = false,
    espHealth = false,
    espHealthBar = true,
    espStyle = "Corner",
    espRainbow = false,
    espPulse = false,
    espFill = false,
    espOutline = true
}
local aimbotSettings = {
    aimbotEnabled = false,
    aimbotKey = "E",
    aimbotMode = "Hold",
    aimbotPart = "Head",
    aimbotFov = 150,
    aimbotSmooth = 0.15,
    aimbotMaxDistance = 800,
    aimbotTeamCheck = true,
    aimbotVisCheck = false,
    aimbotSticky = false,
    aimbotDrawFov = true,
    aimbotFovColor = Color3.fromRGB(255, 255, 255)
}
local silentAimSettings = {
    silentEnabled = false,
    silentPart = "Head",
    silentFov = 120,
    silentMaxDistance = 600,
    silentTeamCheck = true,
    silentVisCheck = true,
    silentHitChance = 100,
    silentDrawFov = false,
    silentFovColor = Color3.fromRGB(255, 100, 100)
}
local silentTarget = nil
local silentFovCircle = nil

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

local function updateEspForPlayer(plr, espCfg)
    local item = ensureEsp(plr)
    if not item then return end
    if not espCfg.espEnabled then
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
    if espCfg.espRainbow then
        local hue = (os.clock() * 0.15) % 1
        color = Color3.fromHSV(hue, 1, 1)
    end
    local alpha = 1
    local thick = 1
    if espCfg.espPulse then
        local t = os.clock() * 3
        local p = (math.sin(t) + 1) * 0.5
        alpha = 0.55 + p * 0.45
        thick = 1 + p * 1.5
    end
    local style = espCfg.espStyle
    if style ~= "Corner" and style ~= "Box" then
        style = "Box"
    end
    if espCfg.espBoxes then
        if style == "Corner" then
            setVisible(item.box, false)
            setVisible(item.boxOutline, false)
            setVisible(item.fill, false)
            setCornerLines(item.corners, x, y, width, height, color, thick, alpha)
        else
            setVisible(item.corners, false)
            if espCfg.espFill then
                item.fill.Size = Vector2.new(width, height)
                item.fill.Position = Vector2.new(x, y)
                item.fill.Color = color
                item.fill.Transparency = 0.85 * alpha
                item.fill.Visible = true
            else
                item.fill.Visible = false
            end
            if espCfg.espOutline then
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
    if espCfg.espTracers then
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
    if espCfg.espNames then
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
    if espCfg.espDistance then
        local dist = (cam.CFrame.Position - cf.Position).Magnitude
        item.distanceText.Text = tostring(math.floor(dist)) .. " studs"
        item.distanceText.Position = Vector2.new(top.X, bottom.Y + 2)
        item.distanceText.Color = color
        item.distanceText.Transparency = alpha
        item.distanceText.Visible = true
    else
        item.distanceText.Visible = false
    end
    if espCfg.espHealth then
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
    if espCfg.espHealthBar then
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

local function updateAllEsp(espCfg)
    for _, plr in ipairs(players:GetPlayers()) do
        if plr ~= players.LocalPlayer then
            updateEspForPlayer(plr, espCfg)
        end
    end
end

local function createEsp(plr)
    if plr and plr ~= players.LocalPlayer then
        ensureEsp(plr)
    end
end

local espConn
local function startEspLoop(espCfg)
    if espConn then
        espConn:Disconnect()
    end
    espConn = runService.RenderStepped:Connect(function()
        updateAllEsp(espCfg)
    end)
end

local aimbotState = {
    active = false,
    keyDown = false,
    target = nil
}
local fovCircle
local aimbotConn
local inputBeganConn
local inputEndedConn

local function ensureFovCircle()
    if fovCircle then return fovCircle end
    if not Drawing or not Drawing.new then return nil end
    local c = Drawing.new("Circle")
    c.Filled = false
    c.Thickness = 1
    c.NumSides = 64
    c.Visible = false
    fovCircle = c
    return c
end

local function updateFovCircle(aimCfg)
    local c = ensureFovCircle()
    if not c then return end
    if not aimCfg.aimbotDrawFov then
        c.Visible = false
        return
    end
    local cam = getCamera()
    if not cam then
        c.Visible = false
        return
    end
    local vp = cam.ViewportSize
    c.Position = Vector2.new(vp.X / 2, vp.Y / 2)
    c.Radius = aimCfg.aimbotFov
    c.Color = aimCfg.aimbotFovColor
    c.Transparency = 0.9
    c.Visible = true
end

local function matchAimKey(input, key)
    if key == "MouseButton2" then
        return input.UserInputType == Enum.UserInputType.MouseButton2
    end
    if key == "MouseButton1" then
        return input.UserInputType == Enum.UserInputType.MouseButton1
    end
    local kc = Enum.KeyCode[key]
    if not kc then return false end
    return input.KeyCode == kc
end

local function isSameTeam(plr)
    local lp = players.LocalPlayer
    if not lp or not plr then return false end
    if not lp.Team or not plr.Team then return false end
    return lp.Team == plr.Team
end

local function getAimPart(char, partName)
    if not char then return nil end
    if partName == "Head" then
        return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    end
    if partName == "UpperTorso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
    end
    if partName == "HumanoidRootPart" then
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
end

local function isVisible(char, part)
    if not part then return false end
    local cam = getCamera()
    if not cam then return false end
    local origin = cam.CFrame.Position
    local dir = part.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { players.LocalPlayer.Character, cam }
    params.IgnoreWater = true
    local res = workspace:Raycast(origin, dir, params)
    if not res then return true end
    return res.Instance and res.Instance:IsDescendantOf(char)
end

local function isValidTarget(plr, aimCfg)
    if not plr or plr == players.LocalPlayer then return false end
    if aimCfg.aimbotTeamCheck and isSameTeam(plr) then return false end
    local char = getChar(plr)
    if not char then return false end
    local hum = getHumanoid(char)
    if hum and hum.Health <= 0 then return false end
    local part = getAimPart(char, aimCfg.aimbotPart)
    if not part then return false end
    local cam = getCamera()
    if not cam then return false end
    local dist = (cam.CFrame.Position - part.Position).Magnitude
    if dist > aimCfg.aimbotMaxDistance then return false end
    local screenPos = cam:WorldToViewportPoint(part.Position)
    if screenPos.Z <= 0 then return false end
    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    local delta = Vector2.new(screenPos.X, screenPos.Y) - center
    if delta.Magnitude > aimCfg.aimbotFov then return false end
    if aimCfg.aimbotVisCheck and not isVisible(char, part) then return false end
    return true
end

local function getClosestTarget(aimCfg)
    local cam = getCamera()
    if not cam then return nil end
    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    local best
    local bestDist = aimCfg.aimbotFov or 150
    for _, plr in ipairs(players:GetPlayers()) do
        if plr ~= players.LocalPlayer and isValidTarget(plr, aimCfg) then
            local char = plr.Character
            local part = getAimPart(char, aimCfg.aimbotPart)
            if part then
                local screenPos = cam:WorldToViewportPoint(part.Position)
                local delta = Vector2.new(screenPos.X, screenPos.Y) - center
                local mag = delta.Magnitude
                if mag <= bestDist then
                    bestDist = mag
                    best = plr
                end
            end
        end
    end
    return best
end

local function getTarget(aimCfg)
    if aimCfg.aimbotSticky and aimbotState.target and isValidTarget(aimbotState.target, aimCfg) then
        return aimbotState.target
    end
    local plr = getClosestTarget(aimCfg)
    aimbotState.target = plr
    return plr
end

local function isAimbotActive(aimCfg)
    if not aimCfg.aimbotEnabled then return false end
    if aimCfg.aimbotMode == "Toggle" then
        return aimbotState.active
    end
    return aimbotState.keyDown
end

local function updateAimbot(aimCfg)
    updateFovCircle(aimCfg)
    if not isAimbotActive(aimCfg) then
        return
    end
    local plr = getTarget(aimCfg)
    if not plr then return end
    local char = getChar(plr)
    if not char then return end
    local part = getAimPart(char, aimCfg.aimbotPart)
    if not part then return end
    local cam = getCamera()
    if not cam then return end
    local cf = CFrame.new(cam.CFrame.Position, part.Position)
    local s = math.clamp(aimCfg.aimbotSmooth, 0.05, 1)
    cam.CFrame = cam.CFrame:Lerp(cf, s)
end

local function setAimbotActive(val)
    aimbotState.active = val
    aimbotState.keyDown = val
    if not val then
        aimbotState.target = nil
    end
end

local function bindAimbotInput(aimCfg)
    if inputBeganConn then inputBeganConn:Disconnect() end
    if inputEndedConn then inputEndedConn:Disconnect() end
    inputBeganConn = userInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if matchAimKey(input, aimCfg.aimbotKey) then
            if aimCfg.aimbotMode == "Toggle" then
                aimbotState.active = not aimbotState.active
                if not aimbotState.active then
                    aimbotState.target = nil
                end
            else
                aimbotState.keyDown = true
            end
        end
    end)
    inputEndedConn = userInputService.InputEnded:Connect(function(input, gpe)
        if gpe then return end
        if matchAimKey(input, aimCfg.aimbotKey) then
            if aimCfg.aimbotMode ~= "Toggle" then
                aimbotState.keyDown = false
                aimbotState.target = nil
            end
        end
    end)
end

local function startAimbotLoop(aimCfg)
    if aimbotConn then
        aimbotConn:Disconnect()
    end
    aimbotConn = runService.RenderStepped:Connect(function()
        updateAimbot(aimCfg)
    end)
end

local function ensureSilentFovCircle()
    if silentFovCircle then return silentFovCircle end
    if not Drawing or not Drawing.new then return nil end
    local c = Drawing.new("Circle")
    c.Filled = false
    c.Thickness = 1
    c.NumSides = 64
    c.Visible = false
    silentFovCircle = c
    return c
end

local function updateSilentFovCircle(silentCfg)
    local c = ensureSilentFovCircle()
    if not c then return end
    if not silentCfg.silentDrawFov or not silentCfg.silentEnabled then
        c.Visible = false
        return
    end
    local cam = getCamera()
    if not cam then
        c.Visible = false
        return
    end
    local vp = cam.ViewportSize
    c.Position = Vector2.new(vp.X / 2, vp.Y / 2)
    c.Radius = silentCfg.silentFov
    c.Color = silentCfg.silentFovColor
    c.Transparency = 0.7
    c.Visible = true
end

local function getSilentPart(char, partName)
    if not char then return nil end
    if partName == "Head" then
        return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    end
    if partName == "UpperTorso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
    end
    if partName == "HumanoidRootPart" then
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
end

local function isSilentVisible(char, part)
    if not part then return false end
    local cam = getCamera()
    if not cam then return false end
    local origin = cam.CFrame.Position
    local dir = part.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { players.LocalPlayer.Character, cam }
    params.IgnoreWater = true
    local res = workspace:Raycast(origin, dir, params)
    if not res then return true end
    return res.Instance and res.Instance:IsDescendantOf(char)
end

local function isSilentTeam(plr)
    local lp = players.LocalPlayer
    if not lp or not plr then return false end
    if not lp.Team or not plr.Team then return false end
    return lp.Team == plr.Team
end

local function isValidSilentTarget(plr, silentCfg)
    if not plr or plr == players.LocalPlayer then return false end
    if silentCfg.silentTeamCheck and isSilentTeam(plr) then return false end
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return false end
    local part = getSilentPart(char, silentCfg.silentPart)
    if not part then return false end
    local cam = getCamera()
    if not cam then return false end
    local dist = (cam.CFrame.Position - part.Position).Magnitude
    if dist > silentCfg.silentMaxDistance then return false end
    local screenPos = cam:WorldToViewportPoint(part.Position)
    if screenPos.Z <= 0 then return false end
    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    local delta = Vector2.new(screenPos.X, screenPos.Y) - center
    if delta.Magnitude > silentCfg.silentFov then return false end
    if silentCfg.silentVisCheck and not isSilentVisible(char, part) then return false end
    return true
end

local function getSilentTarget(silentCfg)
    local cam = getCamera()
    if not cam then return nil end
    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    local best
    local bestDist = silentCfg.silentFov or 120
    for _, plr in ipairs(players:GetPlayers()) do
        if plr ~= players.LocalPlayer and isValidSilentTarget(plr, silentCfg) then
            local char = plr.Character
            local part = getSilentPart(char, silentCfg.silentPart)
            if part then
                local screenPos = cam:WorldToViewportPoint(part.Position)
                local delta = Vector2.new(screenPos.X, screenPos.Y) - center
                local mag = delta.Magnitude
                if mag <= bestDist then
                    bestDist = mag
                    best = plr
                end
            end
        end
    end
    return best
end

local function shouldHit(silentCfg)
    if silentCfg.silentHitChance >= 100 then return true end
    return math.random(1, 100) <= silentCfg.silentHitChance
end

local function getSilentAimPosition(silentCfg)
    if not silentCfg.silentEnabled then return nil end
    local plr = getSilentTarget(silentCfg)
    if not plr then return nil end
    local char = plr.Character
    if not char then return nil end
    local part = getSilentPart(char, silentCfg.silentPart)
    if not part then return nil end
    if not shouldHit(silentCfg) then return nil end
    silentTarget = plr
    return part.Position
end

local function updateSilentAim(silentCfg)
    updateSilentFovCircle(silentCfg)
    if silentCfg.silentEnabled then
        silentTarget = getSilentTarget(silentCfg)
    else
        silentTarget = nil
    end
end

local function getCurrentSilentTarget()
    return silentTarget
end

local function getSilentTargetPosition(silentCfg)
    if not silentCfg.silentEnabled then return nil end
    if not silentTarget then return nil end
    local char = silentTarget.Character
    if not char then return nil end
    local part = getSilentPart(char, silentCfg.silentPart)
    if not part then return nil end
    if not shouldHit(silentCfg) then return nil end
    return part.Position
end

local silentAimConn
local function startSilentAimLoop(silentCfg)
    if silentAimConn then
        silentAimConn:Disconnect()
    end
    silentAimConn = runService.RenderStepped:Connect(function()
        updateSilentAim(silentCfg)
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

local mainTab = Window:Tab({
    Title = "Main",
    Icon = "home"
})

local visualTab = Window:Tab({
    Title = "Visual",
    Icon = "eye"
})

local settingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})

mainTab:Toggle({
    Title = "Aimbot",
    Desc = "Enable aimbot",
    Value = aimbotSettings.aimbotEnabled,
    Callback = function(val)
        aimbotSettings.aimbotEnabled = val
        if not val then
            setAimbotActive(false)
        end
    end
})

mainTab:Dropdown({
    Title = "Aimbot Mode",
    Desc = "Hold or toggle",
    Values = { "Hold", "Toggle" },
    Value = aimbotSettings.aimbotMode,
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
        aimbotSettings.aimbotMode = sel
        setAimbotActive(false)
        bindAimbotInput(aimbotSettings)
    end
})

mainTab:Keybind({
    Title = "Aimbot Key",
    Desc = "Keybind",
    Value = aimbotSettings.aimbotKey,
    Callback = function(v)
        if type(v) ~= "string" then
            return
        end
        aimbotSettings.aimbotKey = v
        bindAimbotInput(aimbotSettings)
    end
})

mainTab:Dropdown({
    Title = "Aim Part",
    Desc = "Target part",
    Values = { "Head", "UpperTorso", "HumanoidRootPart" },
    Value = aimbotSettings.aimbotPart,
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
        aimbotSettings.aimbotPart = sel
    end
})

mainTab:Slider({
    Title = "FOV",
    Desc = "Field of view",
    Step = 5,
    Value = {
        Min = 40,
        Max = 400,
        Default = aimbotSettings.aimbotFov
    },
    Callback = function(val)
        aimbotSettings.aimbotFov = val
    end
})

mainTab:Slider({
    Title = "Smoothness",
    Desc = "Aim smoothing",
    Step = 0.05,
    Value = {
        Min = 0.05,
        Max = 1,
        Default = aimbotSettings.aimbotSmooth
    },
    Callback = function(val)
        aimbotSettings.aimbotSmooth = val
    end
})

mainTab:Slider({
    Title = "Max Distance",
    Desc = "Stud limit",
    Step = 25,
    Value = {
        Min = 50,
        Max = 2000,
        Default = aimbotSettings.aimbotMaxDistance
    },
    Callback = function(val)
        aimbotSettings.aimbotMaxDistance = val
    end
})

mainTab:Toggle({
    Title = "Team Check",
    Desc = "Ignore teammates",
    Value = aimbotSettings.aimbotTeamCheck,
    Callback = function(val)
        aimbotSettings.aimbotTeamCheck = val
    end
})

mainTab:Toggle({
    Title = "Visibility Check",
    Desc = "Wall check",
    Value = aimbotSettings.aimbotVisCheck,
    Callback = function(val)
        aimbotSettings.aimbotVisCheck = val
    end
})

mainTab:Divider()

mainTab:Toggle({
    Title = "Draw FOV",
    Desc = "Show FOV circle",
    Value = aimbotSettings.aimbotDrawFov,
    Callback = function(val)
        aimbotSettings.aimbotDrawFov = val
    end
})

mainTab:Colorpicker({
    Title = "FOV Color",
    Desc = "Circle color",
    Default = aimbotSettings.aimbotFovColor,
    Transparency = 0,
    Callback = function(col)
        aimbotSettings.aimbotFovColor = col
    end
})

mainTab:Toggle({
    Title = "Sticky Aim",
    Desc = "Stay on target",
    Value = aimbotSettings.aimbotSticky,
    Callback = function(val)
        aimbotSettings.aimbotSticky = val
    end
})

mainTab:Divider()

mainTab:Toggle({
    Title = "Silent Aim",
    Desc = "Invisible aimbot",
    Value = silentAimSettings.silentEnabled,
    Callback = function(val)
        silentAimSettings.silentEnabled = val
    end
})

mainTab:Dropdown({
    Title = "Silent Part",
    Desc = "Target body part",
    Values = { "Head", "UpperTorso", "HumanoidRootPart" },
    Value = silentAimSettings.silentPart,
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
        silentAimSettings.silentPart = sel
    end
})

mainTab:Slider({
    Title = "Silent FOV",
    Desc = "Target area",
    Step = 5,
    Value = {
        Min = 30,
        Max = 300,
        Default = silentAimSettings.silentFov
    },
    Callback = function(val)
        silentAimSettings.silentFov = val
    end
})

mainTab:Slider({
    Title = "Silent Distance",
    Desc = "Max stud range",
    Step = 25,
    Value = {
        Min = 50,
        Max = 1500,
        Default = silentAimSettings.silentMaxDistance
    },
    Callback = function(val)
        silentAimSettings.silentMaxDistance = val
    end
})

mainTab:Slider({
    Title = "Hit Chance",
    Desc = "% chance to hit",
    Step = 5,
    Value = {
        Min = 5,
        Max = 100,
        Default = silentAimSettings.silentHitChance
    },
    Callback = function(val)
        silentAimSettings.silentHitChance = val
    end
})

mainTab:Toggle({
    Title = "Silent Team Check",
    Desc = "Ignore teammates",
    Value = silentAimSettings.silentTeamCheck,
    Callback = function(val)
        silentAimSettings.silentTeamCheck = val
    end
})

mainTab:Toggle({
    Title = "Silent Vis Check",
    Desc = "Wall check",
    Value = silentAimSettings.silentVisCheck,
    Callback = function(val)
        silentAimSettings.silentVisCheck = val
    end
})

mainTab:Toggle({
    Title = "Silent Draw FOV",
    Desc = "Show silent FOV",
    Value = silentAimSettings.silentDrawFov,
    Callback = function(val)
        silentAimSettings.silentDrawFov = val
    end
})

mainTab:Colorpicker({
    Title = "Silent FOV Color",
    Desc = "Circle color",
    Default = silentAimSettings.silentFovColor,
    Transparency = 0,
    Callback = function(col)
        silentAimSettings.silentFovColor = col
    end
})

visualTab:Toggle({
    Title = "ESP Enabled",
    Desc = "Main ESP",
    Value = espSettings.espEnabled,
    Callback = function(val)
        espSettings.espEnabled = val
        if not val then
            clearAllEsp()
        end
    end
})

local styleDropdown = visualTab:Dropdown({
    Title = "ESP Style",
    Desc = "Box or corner",
    Values = { "Box", "Corner" },
    Value = espSettings.espStyle,
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
        espSettings.espStyle = sel
    end
})

styleDropdown:Select(espSettings.espStyle)

visualTab:Toggle({
    Title = "ESP Boxes",
    Desc = "Box around player",
    Value = espSettings.espBoxes,
    Callback = function(val)
        espSettings.espBoxes = val
    end
})

visualTab:Toggle({
    Title = "ESP Outline",
    Desc = "Outline for boxes",
    Value = espSettings.espOutline,
    Callback = function(val)
        espSettings.espOutline = val
    end
})

visualTab:Toggle({
    Title = "ESP Fill",
    Desc = "Filled box",
    Value = espSettings.espFill,
    Callback = function(val)
        espSettings.espFill = val
    end
})

visualTab:Toggle({
    Title = "ESP Tracers",
    Desc = "Line to player",
    Value = espSettings.espTracers,
    Callback = function(val)
        espSettings.espTracers = val
    end
})

visualTab:Toggle({
    Title = "ESP Names",
    Desc = "Show player name",
    Value = espSettings.espNames,
    Callback = function(val)
        espSettings.espNames = val
    end
})

visualTab:Toggle({
    Title = "ESP Distance",
    Desc = "Show distance",
    Value = espSettings.espDistance,
    Callback = function(val)
        espSettings.espDistance = val
    end
})

visualTab:Toggle({
    Title = "ESP Health",
    Desc = "Show health",
    Value = espSettings.espHealth,
    Callback = function(val)
        espSettings.espHealth = val
    end
})

visualTab:Toggle({
    Title = "ESP Health Bar",
    Desc = "Health bar",
    Value = espSettings.espHealthBar,
    Callback = function(val)
        espSettings.espHealthBar = val
    end
})

visualTab:Toggle({
    Title = "ESP Rainbow",
    Desc = "Rainbow colors",
    Value = espSettings.espRainbow,
    Callback = function(val)
        espSettings.espRainbow = val
    end
})

visualTab:Toggle({
    Title = "ESP Pulse",
    Desc = "Pulse effect",
    Value = espSettings.espPulse,
    Callback = function(val)
        espSettings.espPulse = val
    end
})

players.PlayerRemoving:Connect(function(plr)
    clearEsp(plr)
end)

startEspLoop(espSettings)
bindAimbotInput(aimbotSettings)
startAimbotLoop(aimbotSettings)
startSilentAimLoop(silentAimSettings)

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