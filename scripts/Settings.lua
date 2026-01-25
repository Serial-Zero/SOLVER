local g=(getgenv and getgenv())or _G
g.strellarSettings=g.strellarSettings or{
    uiScale=1,
    isTransparent=false,
    isKeySystemEnabled=true,
    theme="default"
}

return g.strellarSettings
