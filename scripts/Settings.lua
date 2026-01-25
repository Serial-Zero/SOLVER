local g=(getgenv and getgenv())or _G
g.strellarSettings=g.strellarSettings or{
    uiScale=1,
    isTransparent=true,
    isKeySystemEnabled=false,
    theme="Dark",
    espEnabled=false,
    espBoxes=false,
    espTracers=false,
    espNames=false,
    espDistance=false,
    espHealth=false
}

return g.strellarSettings
