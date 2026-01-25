local g=(getgenv and getgenv())or _G
g.strellarSettings=g.strellarSettings or{
    uiScale=1,
    isTransparent=true,
    isKeySystemEnabled=true,
    theme="Dark",
    espEnabled=false,
    espBoxes=true,
    espTracers=false,
    espNames=true,
    espDistance=true,
    espHealth=true
}

return g.strellarSettings
