local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local settings = loadstring(game:HttpGet("https://raw.githubusercontent.com/DeadSignalFound/SOLVER/refs/heads/main/scripts/Settings.lua"))()
if type(settings) ~= "table" then
    settings = {}
end
if settings.isTransparent == nil then
    settings.isTransparent = true
end
if type(settings.theme) ~= "string" or settings.theme == "" or settings.theme == "default" then
    settings.theme = "Dark"
end

local Window = WindUI:CreateWindow({
    Title = "SOLVER",
    Icon = "door-open", -- lucide icon
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

local settingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})

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