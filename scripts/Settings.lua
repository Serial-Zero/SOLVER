local g=(getgenv and getgenv())or _G
g.strellarSettings=g.strellarSettings or{
    uiScale=1,
    isTransparent=true,
    isKeySystemEnabled=true,
    theme="Dark"
}

return g.strellarSettings
