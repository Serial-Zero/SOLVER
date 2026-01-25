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
    Title = "My Super Hub",
    Icon = "door-open", -- lucide icon
    Author = "by .ftgs and .ftgs",
    Folder = "MySuperHub",
    

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

settingsTab:Button({
    Title = "Test Button",
    Desc = "Test",
    Locked = false,
    Callback = function()
        print("test")
    end
})