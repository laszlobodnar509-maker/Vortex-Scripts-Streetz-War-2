-- Vortex Scripts | Streetz War 2 (Redesigned v2 - Clean)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

local flySpeed = 50
local walkSpeed = 50
local originalWalkSpeed = 16
local isFlying = false
local speedEnabled = false
local noclipEnabled = false
local espEnabled = false
local selectedPlayer = nil
local isSpectating = false

local espSettings = {
    Color = Color3.fromRGB(212, 168, 67),
    Tracers = false,
    Names = true,
    HealthBar = true,
    ShowTools = true
}

local keybinds = {
    Fly = Enum.KeyCode.F,
    Speed = Enum.KeyCode.Q,
    Noclip = Enum.KeyCode.N
}

local waitingForKey = nil

local keysHeld = {
    W = false, S = false, A = false, D = false,
    Space = false, LeftShift = false
}

local aimbotSettings = {
    Enabled = true,
    FOV = 150,
    Smoothness = 0.6,
    VisCheck = true,
    TeamCheck = false,
    AutoSwitch = true,
    OverrideCam = false,
    AimKey = Enum.UserInputType.MouseButton2,
    CenterOffset = Vector2.new(0, 0),
    CircleColor = Color3.fromRGB(212, 168, 67),
    TargetMode = "Center"
}

local currentAimTarget = nil
local holdingAim = false
local lockedCFrame = nil
local screenGui, mainFrame, espDrawings, playerButtonMap = nil, nil, {}, {}
local activeKeybindConnection = nil

local ACCENT = Color3.fromRGB(212, 168, 67)
local ACCENT_DIM = Color3.fromRGB(170, 130, 45)
local SECONDARY = Color3.fromRGB(61, 139, 139)
local SUCCESS = Color3.fromRGB(85, 170, 85)
local BG = Color3.fromRGB(14, 13, 17)
local BG2 = Color3.fromRGB(20, 19, 24)
local CARD = Color3.fromRGB(24, 23, 28)
local CARD_HOVER = Color3.fromRGB(30, 29, 34)
local TEXT = Color3.fromRGB(230, 226, 218)
local TEXT_DIM = Color3.fromRGB(130, 124, 115)
local TEXT_MUTED = Color3.fromRGB(90, 85, 78)
local BORDER = Color3.fromRGB(38, 36, 42)
local PANEL = Color3.fromRGB(18, 17, 22)

local defaultConfig = nil

local function getConfigTable()
    return {
        ESP = {
            Color = {espSettings.Color.R, espSettings.Color.G, espSettings.Color.B},
            Tracers = espSettings.Tracers,
            Names = espSettings.Names,
            HealthBar = espSettings.HealthBar,
            ShowTools = espSettings.ShowTools
        },
        Aimbot = {
            Enabled = aimbotSettings.Enabled,
            FOV = aimbotSettings.FOV,
            Smoothness = aimbotSettings.Smoothness,
            VisCheck = aimbotSettings.VisCheck,
            TeamCheck = aimbotSettings.TeamCheck,
            AutoSwitch = aimbotSettings.AutoSwitch,
            OverrideCam = aimbotSettings.OverrideCam,
            CircleColor = {aimbotSettings.CircleColor.R, aimbotSettings.CircleColor.G, aimbotSettings.CircleColor.B},
            TargetMode = aimbotSettings.TargetMode
        },
        Keybinds = {
            Fly = keybinds.Fly.Name,
            Speed = keybinds.Speed.Name,
            Noclip = keybinds.Noclip.Name
        },
        FlySpeed = flySpeed,
        WalkSpeed = walkSpeed
    }
end

local function saveConfig()
    local cfg = getConfigTable()
    defaultConfig = cfg
    local ok, str = pcall(function() return HttpService:JSONEncode(cfg) end)
    if not ok or not str then
        str = HttpService:JSONEncode(cfg)
    end
    pcall(function() setclipboard(str) end)
    return str
end

local function cleanConfigString(raw)
    if not raw or type(raw) ~= "string" then return "" end
    raw = raw:match("^%s*(.-)%s*$") or ""
    raw = raw:gsub("\r\n", ""):gsub("\n", ""):gsub("\r", "")
    raw = raw:gsub("\\n", ""):gsub("\\r", "")
    raw = raw:gsub("[\226\128\130\226\128\132\226\128\139\226\128\140\226\128\141]", "")
    if raw:sub(1, 1) == '"' and raw:sub(-1) == '"' then
        raw = raw:sub(2, -2)
    end
    return raw
end

local function applyConfig(cfg)
    if cfg.ESP then
        if cfg.ESP.Color then
            espSettings.Color = Color3.new(cfg.ESP.Color[1], cfg.ESP.Color[2], cfg.ESP.Color[3])
        end
        if cfg.ESP.Tracers ~= nil then espSettings.Tracers = cfg.ESP.Tracers end
        if cfg.ESP.Names ~= nil then espSettings.Names = cfg.ESP.Names end
        if cfg.ESP.HealthBar ~= nil then espSettings.HealthBar = cfg.ESP.HealthBar end
        if cfg.ESP.ShowTools ~= nil then espSettings.ShowTools = cfg.ESP.ShowTools end
    end
    if cfg.Aimbot then
        if cfg.Aimbot.Enabled ~= nil then aimbotSettings.Enabled = cfg.Aimbot.Enabled end
        if cfg.Aimbot.FOV then aimbotSettings.FOV = cfg.Aimbot.FOV end
        if cfg.Aimbot.Smoothness then aimbotSettings.Smoothness = cfg.Aimbot.Smoothness end
        if cfg.Aimbot.VisCheck ~= nil then aimbotSettings.VisCheck = cfg.Aimbot.VisCheck end
        if cfg.Aimbot.TeamCheck ~= nil then aimbotSettings.TeamCheck = cfg.Aimbot.TeamCheck end
        if cfg.Aimbot.AutoSwitch ~= nil then aimbotSettings.AutoSwitch = cfg.Aimbot.AutoSwitch end
        if cfg.Aimbot.OverrideCam ~= nil then aimbotSettings.OverrideCam = cfg.Aimbot.OverrideCam end
        if cfg.Aimbot.CircleColor then
            aimbotSettings.CircleColor = Color3.new(cfg.Aimbot.CircleColor[1], cfg.Aimbot.CircleColor[2], cfg.Aimbot.CircleColor[3])
        end
        if cfg.Aimbot.TargetMode then aimbotSettings.TargetMode = cfg.Aimbot.TargetMode end
    end
    if cfg.Keybinds then
        if cfg.Keybinds.Fly then keybinds.Fly = Enum.KeyCode[cfg.Keybinds.Fly] or keybinds.Fly end
        if cfg.Keybinds.Speed then keybinds.Speed = Enum.KeyCode[cfg.Keybinds.Speed] or keybinds.Speed end
        if cfg.Keybinds.Noclip then keybinds.Noclip = Enum.KeyCode[cfg.Keybinds.Noclip] or keybinds.Noclip end
    end
    if cfg.FlySpeed then flySpeed = cfg.FlySpeed end
    if cfg.WalkSpeed then walkSpeed = cfg.WalkSpeed end
end

local function cleanupOnDeath()
    isFlying = false; speedEnabled = false; noclipEnabled = false
    espEnabled = false; isSpectating = false; selectedPlayer = nil
    waitingForKey = nil; currentAimTarget = nil; holdingAim = false
    if localPlayer.Character then
        local h = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then
            h.PlatformStand = false
            h.WalkSpeed = originalWalkSpeed
        end
    end
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
    end
    espDrawings = {}
    playerButtonMap = {}
end

local function safeCall(tag, fn)
    local ok, err = pcall(fn)
    if not ok then
        warn("[Vortex] " .. tag .. ": " .. tostring(err))
    end
end

local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function addStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or BORDER
    s.Thickness = thickness or 0.5
    s.Parent = parent
    return s
end

local function hookHover(btn, baseColor)
    btn.MouseEnter:Connect(function()
        if btn.Parent then
            TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = CARD_HOVER}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if btn.Parent then
            TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = baseColor}):Play()
        end
    end)
end

local function pressAnim(btn)
    local sz = btn.Size
    local ti = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local shrink = TweenService:Create(btn, ti, {Size = sz - UDim2.new(0, 3, 0, 2)})
    local grow = TweenService:Create(btn, ti, {Size = sz})
    shrink:Play()
    shrink.Completed:Connect(function() grow:Play() end)
end

local function newButton(text, parent, bg, tc, sz)
    local b = Instance.new("TextButton")
    b.Size = sz or UDim2.new(1, -6, 0, 28)
    b.BackgroundColor3 = bg or CARD
    b.TextColor3 = tc or TEXT
    b.TextSize = 11
    b.Font = Enum.Font.GothamSemibold
    b.Text = text
    b.AutoButtonColor = false
    b.Parent = parent
    addCorner(b, 6)
    addStroke(b, BORDER, 0.5)
    hookHover(b, bg or CARD)
    b.MouseButton1Click:Connect(function() pressAnim(b) end)
    return b
end

local function newInput(placeholder, default, parent)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -6, 0, 26)
    box.BackgroundColor3 = PANEL
    box.TextColor3 = TEXT
    box.PlaceholderColor3 = TEXT_MUTED
    box.TextSize = 11
    box.Font = Enum.Font.Gotham
    box.PlaceholderText = placeholder
    box.Text = default or ""
    box.ClearTextOnFocus = false
    box.Parent = parent
    addCorner(box, 6)
    local st = addStroke(box, BORDER, 0.5)
    box.Focused:Connect(function()
        TweenService:Create(box, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = CARD_HOVER}):Play()
        st.Color = ACCENT_DIM
        st.Thickness = 1
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(box, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = PANEL}):Play()
        st.Color = BORDER
        st.Thickness = 0.5
    end)
    return box
end

local function newKeyBox(label, key, parent)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -6, 0, 28)
    b.BackgroundColor3 = PANEL
    b.TextColor3 = TEXT_DIM
    b.TextSize = 11
    b.Font = Enum.Font.Gotham
    b.Text = label .. "  [  " .. key.Name .. "  ]"
    b.AutoButtonColor = false
    b.Parent = parent
    addCorner(b, 6)
    local st = addStroke(b, BORDER, 0.5)
    hookHover(b, PANEL)
    b.MouseButton1Click:Connect(function()
        pressAnim(b)
        waitingForKey = label
        b.Text = "  PRESS ANY KEY..."
        b.TextColor3 = ACCENT
        st.Color = ACCENT
        st.Thickness = 1
    end)
    return b
end

local function newSectionHeader(text, accentColor, parent)
    local hdr = Instance.new("Frame")
    hdr.Size = UDim2.new(1, 0, 0, 26)
    hdr.BackgroundTransparency = 1
    hdr.Parent = parent
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 2, 1, 0)
    bar.BackgroundColor3 = accentColor or ACCENT
    bar.Parent = hdr
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = accentColor or ACCENT
    lbl.TextSize = 10
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = hdr
    return hdr
end

local function setupGUI(skipInit)
    if screenGui then screenGui:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "VortexControlGui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = localPlayer:WaitForChild("PlayerGui")
    screenGui = gui

    task.spawn(function()
        local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        local hum = char:WaitForChild("Humanoid", 3)
        if hum then originalWalkSpeed = hum.WalkSpeed end
    end)

    ----------------------------------------
    -- LOADING SCREEN
    ----------------------------------------
    local blur = Instance.new("Frame")
    blur.Name = "LoadingBlur"
    blur.Size = UDim2.new(1, 0, 1, 0)
    blur.BackgroundColor3 = Color3.fromRGB(6, 6, 9)
    blur.BackgroundTransparency = skipInit and 1 or 0
    blur.Parent = gui

    local lf = Instance.new("Frame")
    lf.Size = UDim2.new(0, 460, 0, 260)
    lf.AnchorPoint = Vector2.new(0.5, 0.5)
    lf.Position = UDim2.new(0.5, 0, 0.5, 0)
    lf.BackgroundColor3 = BG2
    lf.BorderSizePixel = 0
    lf.Visible = not skipInit
    lf.Parent = blur
    addCorner(lf, 14)
    addStroke(lf, ACCENT_DIM, 1)

    local topLine = Instance.new("Frame")
    topLine.Size = UDim2.new(1, -28, 0, 2)
    topLine.Position = UDim2.new(0, 14, 0, 0)
    topLine.BackgroundColor3 = ACCENT
    topLine.Parent = lf

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 38)
    title.Position = UDim2.new(0, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.TextColor3 = TEXT
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.Text = "STREETZ WAR 2"
    title.Parent = lf

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 18)
    sub.Position = UDim2.new(0, 0, 0, 68)
    sub.BackgroundTransparency = 1
    sub.TextColor3 = ACCENT
    sub.TextSize = 12
    sub.Font = Enum.Font.GothamMedium
    sub.Text = "VORTEX  -  SECURE LOADER"
    sub.Parent = lf

    local underline = Instance.new("Frame")
    underline.Size = UDim2.new(0, 60, 0, 1)
    underline.Position = UDim2.new(0.5, -30, 0, 86)
    underline.BackgroundColor3 = ACCENT_DIM
    underline.Parent = lf

    local ver = Instance.new("TextLabel")
    ver.Size = UDim2.new(1, 0, 0, 16)
    ver.Position = UDim2.new(0, 0, 0, 94)
    ver.BackgroundTransparency = 1
    ver.TextColor3 = TEXT_MUTED
    ver.TextSize = 10
    ver.Font = Enum.Font.Gotham
    ver.Text = "v2.5.0  -  Streetz War 2 Edition"
    ver.Parent = lf

    local feat = Instance.new("TextLabel")
    feat.Size = UDim2.new(1, -40, 0, 14)
    feat.Position = UDim2.new(0, 20, 0, 130)
    feat.BackgroundTransparency = 1
    feat.TextColor3 = TEXT_DIM
    feat.TextSize = 10
    feat.Font = Enum.Font.Gotham
    feat.Text = "* ESP  -  Aimbot  -  Fly  -  Speed  -  Noclip  -  Teleport"
    feat.TextXAlignment = Enum.TextXAlignment.Left
    feat.Parent = lf

    local feat2 = Instance.new("TextLabel")
    feat2.Size = UDim2.new(1, -40, 0, 14)
    feat2.Position = UDim2.new(0, 20, 0, 146)
    feat2.BackgroundTransparency = 1
    feat2.TextColor3 = TEXT_DIM
    feat2.TextSize = 10
    feat2.Font = Enum.Font.Gotham
    feat2.Text = "* Locations  -  Spectate  -  Keybinds  -  Config"
    feat2.TextXAlignment = Enum.TextXAlignment.Left
    feat2.Parent = lf

    local initBtn = Instance.new("TextButton")
    initBtn.Size = UDim2.new(0, 260, 0, 42)
    initBtn.AnchorPoint = Vector2.new(0.5, 0)
    initBtn.Position = UDim2.new(0.5, 0, 0, 192)
    initBtn.BackgroundColor3 = ACCENT
    initBtn.TextColor3 = Color3.fromRGB(12, 10, 8)
    initBtn.TextSize = 13
    initBtn.Font = Enum.Font.GothamBold
    initBtn.Text = "INITIALIZE"
    initBtn.AutoButtonColor = false
    initBtn.Parent = lf
    addCorner(initBtn, 8)
    addStroke(initBtn, ACCENT, 1)
    hookHover(initBtn, ACCENT)

    ----------------------------------------
    -- FOV CIRCLE
    ----------------------------------------
    local fovCircle = Instance.new("Frame")
    fovCircle.Name = "FOVCircle"
    fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    fovCircle.BackgroundTransparency = 1
    fovCircle.Visible = false
    fovCircle.ZIndex = 100
    fovCircle.Parent = gui
    local fovCorner = Instance.new("UICorner")
    fovCorner.CornerRadius = UDim.new(1, 0)
    fovCorner.Parent = fovCircle
    local fovStroke = Instance.new("UIStroke")
    fovStroke.Name = "FOVStroke"
    fovStroke.Color = aimbotSettings.CircleColor
    fovStroke.Thickness = 1.5
    fovStroke.Parent = fovCircle

    ----------------------------------------
    -- MAIN FRAME
    ----------------------------------------
    local mf = Instance.new("Frame")
    mf.Size = UDim2.new(0, 980, 0, 470)
    mf.AnchorPoint = Vector2.new(0.5, 0.5)
    mf.Position = UDim2.new(0.5, 0, 0.5, 0)
    mf.BackgroundColor3 = BG
    mf.BorderSizePixel = 0
    mf.Active = true
    mf.Draggable = true
    mf.Visible = skipInit
    mf.ZIndex = 50
    mf.Parent = gui
    mainFrame = mf
    addCorner(mf, 12)
    addStroke(mf, BORDER, 1)

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 3)
    topBar.BackgroundColor3 = ACCENT
    topBar.Parent = mf

    local titleBar = Instance.new("TextLabel")
    titleBar.Size = UDim2.new(1, -44, 0, 40)
    titleBar.Position = UDim2.new(0, 22, 0, 0)
    titleBar.BackgroundColor3 = BG2
    titleBar.TextColor3 = ACCENT
    titleBar.TextSize = 13
    titleBar.Font = Enum.Font.GothamBold
    titleBar.Text = "  VORTEX SCRIPTS  |  STREETZ WAR 2  -  Right-Click ESP for settings  |  Toggle: P"
    titleBar.TextXAlignment = Enum.TextXAlignment.Left
    titleBar.Parent = mf
    addCorner(titleBar, 12)
    addStroke(titleBar, BORDER, 0.5)

    local btmBar = Instance.new("Frame")
    btmBar.Size = UDim2.new(1, 0, 0, 22)
    btmBar.Position = UDim2.new(0, 0, 1, -22)
    btmBar.BackgroundColor3 = BG2
    btmBar.Parent = mf
    local btmLabel = Instance.new("TextLabel")
    btmLabel.Size = UDim2.new(1, 0, 1, 0)
    btmLabel.BackgroundTransparency = 1
    btmLabel.TextColor3 = TEXT_MUTED
    btmLabel.TextSize = 9
    btmLabel.Font = Enum.Font.Gotham
    btmLabel.Text = "Vortex Scripts  -  Streetz War 2  -  Use at own risk"
    btmLabel.Parent = btmBar
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(1, -16, 0, 8)
    dot.BackgroundColor3 = SUCCESS
    dot.Parent = btmBar
    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot

    ----------------------------------------
    -- PLAYER LIST (Column 1)
    ----------------------------------------
    local playerScroll = Instance.new("ScrollingFrame")
    playerScroll.Size = UDim2.new(0, 185, 0, 395)
    playerScroll.Position = UDim2.new(0, 14, 0, 52)
    playerScroll.BackgroundColor3 = PANEL
    playerScroll.BorderSizePixel = 0
    playerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    playerScroll.ScrollBarThickness = 3
    playerScroll.ScrollBarImageColor3 = TEXT_MUTED
    playerScroll.ZIndex = 2
    playerScroll.Parent = mf
    addCorner(playerScroll, 8)
    addStroke(playerScroll, BORDER, 0.5)
    local pLayout = Instance.new("UIListLayout")
    pLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pLayout.Padding = UDim.new(0, 4)
    pLayout.Parent = playerScroll

    newSectionHeader("PLAYERS", ACCENT, playerScroll)

    ----------------------------------------
    -- CONTROLS (Column 2)
    ----------------------------------------
    local ctrlScroll = Instance.new("ScrollingFrame")
    ctrlScroll.Size = UDim2.new(0, 230, 0, 395)
    ctrlScroll.Position = UDim2.new(0, 208, 0, 52)
    ctrlScroll.BackgroundTransparency = 1
    ctrlScroll.BorderSizePixel = 0
    ctrlScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ctrlScroll.ScrollBarThickness = 3
    ctrlScroll.ScrollBarImageColor3 = TEXT_MUTED
    ctrlScroll.ZIndex = 2
    ctrlScroll.Parent = mf
    local cLayout = Instance.new("UIListLayout")
    cLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cLayout.Padding = UDim.new(0, 6)
    cLayout.Parent = ctrlScroll

    ----------------------------------------
    -- LOCATIONS (Column 3)
    ----------------------------------------
    local locScroll = Instance.new("ScrollingFrame")
    locScroll.Size = UDim2.new(0, 245, 0, 355)
    locScroll.Position = UDim2.new(0, 450, 0, 90)
    locScroll.BackgroundColor3 = PANEL
    locScroll.BorderSizePixel = 0
    locScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    locScroll.ScrollBarThickness = 3
    locScroll.ScrollBarImageColor3 = TEXT_MUTED
    locScroll.ZIndex = 2
    locScroll.Parent = mf
    addCorner(locScroll, 8)
    addStroke(locScroll, BORDER, 0.5)
    local lLayout = Instance.new("UIListLayout")
    lLayout.SortOrder = Enum.SortOrder.LayoutOrder
    lLayout.Padding = UDim.new(0, 4)
    lLayout.Parent = locScroll

    newSectionHeader("LOCATIONS", ACCENT, locScroll)

    local locSearch = newInput("Search locations...", "", locScroll)
    locSearch.Size = UDim2.new(1, -12, 0, 28)
    locSearch.Position = UDim2.new(0, 6, 0, 30)

    ----------------------------------------
    -- AIMBOT (Column 4)
    ----------------------------------------
    local aimScroll = Instance.new("ScrollingFrame")
    aimScroll.Size = UDim2.new(0, 245, 0, 395)
    aimScroll.Position = UDim2.new(0, 710, 0, 52)
    aimScroll.BackgroundColor3 = PANEL
    aimScroll.BorderSizePixel = 0
    aimScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    aimScroll.ScrollBarThickness = 3
    aimScroll.ScrollBarImageColor3 = TEXT_MUTED
    aimScroll.ZIndex = 2
    aimScroll.Parent = mf
    addCorner(aimScroll, 8)
    addStroke(aimScroll, BORDER, 0.5)
    local aLayout = Instance.new("UIListLayout")
    aLayout.SortOrder = Enum.SortOrder.LayoutOrder
    aLayout.Padding = UDim.new(0, 6)
    aLayout.Parent = aimScroll

    newSectionHeader("AIMBOT", SECONDARY, aimScroll)

    ----------------------------------------
    -- CONTROL BUTTONS
    ----------------------------------------
    local tpButton = newButton("Teleport To Selected", ctrlScroll, ACCENT, Color3.fromRGB(12, 10, 8))
    local specButton = newButton("View Perspective: OFF", ctrlScroll, CARD, TEXT)
    local flyBtn = newButton("Fly: OFF", ctrlScroll, CARD, TEXT)
    local flyInput = newInput("Fly Speed (Default 50)", tostring(flySpeed), ctrlScroll)
    local flyKey = newKeyBox("Fly", keybinds.Fly, ctrlScroll)
    local spdBtn = newButton("Speed Hack: OFF", ctrlScroll, CARD, TEXT)
    local spdInput = newInput("WalkSpeed (Default 50)", tostring(walkSpeed), ctrlScroll)
    local spdKey = newKeyBox("Speed", keybinds.Speed, ctrlScroll)
    local noclipBtn = newButton("Noclip: OFF", ctrlScroll, CARD, TEXT)
    local noclipKey = newKeyBox("Noclip", keybinds.Noclip, ctrlScroll)
    local espBtn = newButton("ESP: OFF", ctrlScroll, CARD, TEXT)
    local homeBtn = newButton("Teleport To Home", ctrlScroll, SECONDARY, Color3.fromRGB(12, 10, 8))

    ----------------------------------------
    -- CONFIG SECTION
    ----------------------------------------
    newSectionHeader("CONFIG", Color3.fromRGB(180, 140, 60), ctrlScroll)

    local configBox = newInput("Paste config here...", "", ctrlScroll)
    configBox.Size = UDim2.new(1, -6, 0, 60)
    configBox.TextXAlignment = Enum.TextXAlignment.Left
    configBox.TextYAlignment = Enum.TextYAlignment.Top
    configBox.TextWrapped = false
    configBox.MultiLine = true
    configBox.Font = Enum.Font.Code
    configBox.TextSize = 8
    configBox.ClearTextOnFocus = false

    local saveBtn = newButton("Save Config (Copy)", ctrlScroll, SUCCESS, Color3.fromRGB(12, 10, 8))
    local loadBtn = newButton("Load Config (Paste)", ctrlScroll, SECONDARY, Color3.fromRGB(12, 10, 8))
    local resetBtn = newButton("Reset Defaults", ctrlScroll, Color3.fromRGB(180, 70, 70), Color3.fromRGB(255, 255, 255))
    local cfgStatusLbl = Instance.new("TextLabel")
    cfgStatusLbl.Size = UDim2.new(1, -6, 0, 18)
    cfgStatusLbl.BackgroundTransparency = 1
    cfgStatusLbl.TextColor3 = TEXT_MUTED
    cfgStatusLbl.TextSize = 10
    cfgStatusLbl.Font = Enum.Font.Gotham
    cfgStatusLbl.Text = ""
    cfgStatusLbl.Parent = ctrlScroll

    saveBtn.MouseButton1Click:Connect(function()
        pressAnim(saveBtn)
        local str = saveConfig()
        configBox.Text = str
        local copied = false
        pcall(function()
            local c = getclipboard()
            copied = (c == str)
        end)
        cfgStatusLbl.Text = copied and "Config copied to clipboard!" or "Config shown below - copy it!"
        cfgStatusLbl.TextColor3 = SUCCESS
        task.delay(3, function() cfgStatusLbl.Text = "" end)
    end)

    loadBtn.MouseButton1Click:Connect(function()
        pressAnim(loadBtn)
        local raw = configBox.Text
        if raw == nil or raw == "" then
            pcall(function()
                local clip = getclipboard()
                if clip and clip ~= "" then
                    raw = clip
                end
            end)
        end
        raw = cleanConfigString(raw)
        if raw == "" then
            cfgStatusLbl.Text = "No config to load!"
            cfgStatusLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
            task.delay(3, function() cfgStatusLbl.Text = "" end)
            return
        end
        local ok, cfg = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and type(cfg) == "table" then
            applyConfig(cfg)
            if screenGui then screenGui:Destroy() end
            espDrawings = {}
            playerButtonMap = {}
            setupGUI(true)
            cfgStatusLbl.Text = "Config loaded!"
            cfgStatusLbl.TextColor3 = SUCCESS
        else
            cfgStatusLbl.Text = "Invalid config!"
            cfgStatusLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
            task.delay(3, function() cfgStatusLbl.Text = "" end)
        end
    end)

    resetBtn.MouseButton1Click:Connect(function()
        pressAnim(resetBtn)
        applyConfig({
            ESP = {Color = {212/255, 168/255, 67/255}, Tracers = false, Names = true, HealthBar = true, ShowTools = true},
            Aimbot = {Enabled = true, FOV = 150, Smoothness = 0.6, VisCheck = true, TeamCheck = false, AutoSwitch = true, OverrideCam = false, CircleColor = {212/255, 168/255, 67/255}, TargetMode = "Center"},
            Keybinds = {Fly = "F", Speed = "Q", Noclip = "N"},
            FlySpeed = 50, WalkSpeed = 50
        })
        if screenGui then screenGui:Destroy() end
        espDrawings = {}
        playerButtonMap = {}
        setupGUI(true)
        cfgStatusLbl.Text = "Defaults restored!"
        cfgStatusLbl.TextColor3 = ACCENT
        task.delay(3, function() cfgStatusLbl.Text = "" end)
    end)

    ----------------------------------------
    -- ESP SETTINGS POPUP
    ----------------------------------------
    local espPopup = Instance.new("Frame")
    espPopup.Size = UDim2.new(0, 225, 0, 312)
    espPopup.Position = UDim2.new(1, 10, 0, 0)
    espPopup.BackgroundColor3 = PANEL
    espPopup.BorderSizePixel = 0
    espPopup.Visible = false
    espPopup.ZIndex = 60
    espPopup.Parent = mf
    addCorner(espPopup, 8)
    addStroke(espPopup, ACCENT_DIM, 1)
    local espLayout = Instance.new("UIListLayout")
    espLayout.SortOrder = Enum.SortOrder.LayoutOrder
    espLayout.Padding = UDim.new(0, 6)
    espLayout.Parent = espPopup

    local espHdr = Instance.new("Frame")
    espHdr.Size = UDim2.new(1, 0, 0, 28)
    espHdr.BackgroundColor3 = CARD
    espHdr.Parent = espPopup
    local espHdrBar = Instance.new("Frame")
    espHdrBar.Size = UDim2.new(0, 3, 1, 0)
    espHdrBar.BackgroundColor3 = ACCENT
    espHdrBar.Parent = espHdr
    local espHdrLbl = Instance.new("TextLabel")
    espHdrLbl.Size = UDim2.new(1, -10, 1, 0)
    espHdrLbl.Position = UDim2.new(0, 10, 0, 0)
    espHdrLbl.BackgroundTransparency = 1
    espHdrLbl.TextColor3 = ACCENT
    espHdrLbl.TextSize = 11
    espHdrLbl.Font = Enum.Font.GothamBold
    espHdrLbl.Text = "ESP CONFIGURATION"
    espHdrLbl.Parent = espHdr

    local function addEspToggle(text, key)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -8, 0, 28)
        b.BackgroundColor3 = espSettings[key] and SUCCESS or CARD
        b.TextColor3 = espSettings[key] and Color3.fromRGB(12, 10, 8) or TEXT
        b.TextSize = 11
        b.Font = Enum.Font.GothamSemibold
        b.Text = text .. ":  " .. (espSettings[key] and "ON" or "OFF")
        b.AutoButtonColor = false
        b.Parent = espPopup
        addCorner(b, 5)
        local st = addStroke(b, BORDER, 0.5)
        hookHover(b, espSettings[key] and SUCCESS or CARD)
        b.MouseButton1Click:Connect(function()
            pressAnim(b)
            espSettings[key] = not espSettings[key]
            b.Text = text .. ":  " .. (espSettings[key] and "ON" or "OFF")
            b.BackgroundColor3 = espSettings[key] and SUCCESS or CARD
            b.TextColor3 = espSettings[key] and Color3.fromRGB(12, 10, 8) or TEXT
            st.Color = espSettings[key] and SUCCESS or BORDER
        end)
    end

    addEspToggle("Show Names", "Names")
    addEspToggle("Show Health Bar", "HealthBar")
    addEspToggle("Show Tracers", "Tracers")
    addEspToggle("Show Backpack Tools", "ShowTools")

    local colorLbl = Instance.new("TextLabel")
    colorLbl.Size = UDim2.new(1, -8, 0, 18)
    colorLbl.BackgroundTransparency = 1
    colorLbl.TextColor3 = TEXT_MUTED
    colorLbl.TextSize = 10
    colorLbl.Font = Enum.Font.Gotham
    colorLbl.Text = "  Theme Colors:"
    colorLbl.TextXAlignment = Enum.TextXAlignment.Left
    colorLbl.Parent = espPopup

    local colorRow = Instance.new("Frame")
    colorRow.Size = UDim2.new(1, -8, 0, 26)
    colorRow.BackgroundTransparency = 1
    colorRow.Parent = espPopup
    local colorLayout = Instance.new("UIListLayout")
    colorLayout.FillDirection = Enum.FillDirection.Horizontal
    colorLayout.SortOrder = Enum.SortOrder.LayoutOrder
    colorLayout.Padding = UDim.new(0, 4)
    colorLayout.Parent = colorRow

    local function addColorBtn(name, col)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 50, 1, 0)
        b.BackgroundColor3 = col
        b.Text = name
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.TextSize = 10
        b.Font = Enum.Font.GothamBold
        b.AutoButtonColor = false
        b.Parent = colorRow
        addCorner(b, 5)
        addStroke(b, Color3.new(0, 0, 0), 0.5)
        b.MouseButton1Click:Connect(function()
            espSettings.Color = col
            pressAnim(b)
        end)
    end

    addColorBtn("Amber", Color3.fromRGB(212, 168, 67))
    addColorBtn("Teal", Color3.fromRGB(61, 139, 139))
    addColorBtn("Emerald", Color3.fromRGB(85, 170, 85))
    addColorBtn("Gold", Color3.fromRGB(218, 185, 50))

    espBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            espPopup.Visible = not espPopup.Visible
        end
    end)

    ----------------------------------------
    -- AIMBOT CONTROLS
    ----------------------------------------
    local function addAimToggle(text, key)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -6, 0, 28)
        b.BackgroundColor3 = aimbotSettings[key] and SECONDARY or CARD
        b.TextColor3 = aimbotSettings[key] and Color3.fromRGB(12, 10, 8) or TEXT
        b.TextSize = 11
        b.Font = Enum.Font.GothamSemibold
        b.Text = text .. ":  " .. (aimbotSettings[key] and "ON" or "OFF")
        b.AutoButtonColor = false
        b.Parent = aimScroll
        addCorner(b, 5)
        local st = addStroke(b, BORDER, 0.5)
        hookHover(b, aimbotSettings[key] and SECONDARY or CARD)
        b.MouseButton1Click:Connect(function()
            pressAnim(b)
            aimbotSettings[key] = not aimbotSettings[key]
            b.Text = text .. ":  " .. (aimbotSettings[key] and "ON" or "OFF")
            b.BackgroundColor3 = aimbotSettings[key] and SECONDARY or CARD
            b.TextColor3 = aimbotSettings[key] and Color3.fromRGB(12, 10, 8) or TEXT
            st.Color = aimbotSettings[key] and SECONDARY or BORDER
        end)
    end

    local function addAimSlider(text, key, min, max)
        local ctr = Instance.new("Frame")
        ctr.Size = UDim2.new(1, -6, 0, 44)
        ctr.BackgroundTransparency = 1
        ctr.Parent = aimScroll
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 16)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = TEXT_MUTED
        lbl.TextSize = 10
        lbl.Font = Enum.Font.Gotham
        lbl.Text = text .. ":  " .. tostring(aimbotSettings[key])
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = ctr
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, 0, 0, 24)
        box.Position = UDim2.new(0, 0, 0, 18)
        box.BackgroundColor3 = CARD
        box.TextColor3 = TEXT
        box.TextSize = 11
        box.Font = Enum.Font.Gotham
        box.Text = tostring(aimbotSettings[key])
        box.ClearTextOnFocus = false
        box.Parent = ctr
        addCorner(box, 5)
        local st = addStroke(box, BORDER, 0.5)
        box.Focused:Connect(function() st.Color = ACCENT_DIM end)
        box.FocusLost:Connect(function()
            local val = tonumber(box.Text)
            if val then
                val = math.clamp(val, min, max)
                aimbotSettings[key] = val
                box.Text = tostring(val)
                lbl.Text = text .. ":  " .. tostring(val)
            else
                box.Text = tostring(aimbotSettings[key])
            end
            st.Color = BORDER
        end)
    end

    addAimToggle("Aimbot Master", "Enabled")
    addAimSlider("FOV Size", "FOV", 10, 800)
    addAimSlider("Smoothness", "Smoothness", 0.01, 1)
    addAimToggle("Wall Check", "VisCheck")
    addAimToggle("Team Check", "TeamCheck")
    addAimToggle("Auto Switch Targets", "AutoSwitch")
    addAimToggle("Override Camera", "OverrideCam")

    local targetModeBtn = newButton("Priority: Screen Center", aimScroll, CARD, TEXT)
    targetModeBtn.MouseButton1Click:Connect(function()
        if aimbotSettings.TargetMode == "Center" then
            aimbotSettings.TargetMode = "Character"
            targetModeBtn.Text = "Priority: My Character"
            targetModeBtn.BackgroundColor3 = SECONDARY
            targetModeBtn.TextColor3 = Color3.fromRGB(12, 10, 8)
        else
            aimbotSettings.TargetMode = "Center"
            targetModeBtn.Text = "Priority: Screen Center"
            targetModeBtn.BackgroundColor3 = CARD
            targetModeBtn.TextColor3 = TEXT
        end
    end)

    local fovColorLbl = Instance.new("TextLabel")
    fovColorLbl.Size = UDim2.new(1, -6, 0, 16)
    fovColorLbl.BackgroundTransparency = 1
    fovColorLbl.TextColor3 = TEXT_MUTED
    fovColorLbl.TextSize = 10
    fovColorLbl.Font = Enum.Font.Gotham
    fovColorLbl.Text = "  FOV Circle Color:"
    fovColorLbl.TextXAlignment = Enum.TextXAlignment.Left
    fovColorLbl.Parent = aimScroll

    local fovColorRow = Instance.new("Frame")
    fovColorRow.Size = UDim2.new(1, -6, 0, 26)
    fovColorRow.BackgroundTransparency = 1
    fovColorRow.Parent = aimScroll
    local fovColorLayout = Instance.new("UIListLayout")
    fovColorLayout.FillDirection = Enum.FillDirection.Horizontal
    fovColorLayout.SortOrder = Enum.SortOrder.LayoutOrder
    fovColorLayout.Padding = UDim.new(0, 4)
    fovColorLayout.Parent = fovColorRow

    local function addFovColor(name, col)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 52, 1, 0)
        b.BackgroundColor3 = col
        b.Text = name
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.TextSize = 10
        b.Font = Enum.Font.GothamBold
        b.AutoButtonColor = false
        b.Parent = fovColorRow
        addCorner(b, 5)
        addStroke(b, Color3.new(0, 0, 0), 0.5)
        b.MouseButton1Click:Connect(function()
            aimbotSettings.CircleColor = col
            if fovCircle and fovCircle:FindFirstChild("FOVStroke") then
                fovCircle.FOVStroke.Color = col
            end
        end)
    end

    addFovColor("Amber", Color3.fromRGB(212, 168, 67))
    addFovColor("Teal", Color3.fromRGB(61, 139, 139))
    addFovColor("Emerald", Color3.fromRGB(85, 170, 85))
    addFovColor("Gold", Color3.fromRGB(218, 185, 50))

    ----------------------------------------
    -- ESP 3D
    ----------------------------------------
    local function addESP(player)
        if player == localPlayer then return end
        local box = Instance.new("Frame")
        box.BackgroundTransparency = 1
        box.Visible = false
        box.ZIndex = 100
        box.Parent = gui
        local stroke = Instance.new("UIStroke")
        stroke.Color = espSettings.Color
        stroke.Thickness = 1.5
        stroke.Parent = box

        local hbar = Instance.new("Frame")
        hbar.Name = "HealthBar"
        hbar.Size = UDim2.new(0, 3, 1, 0)
        hbar.Position = UDim2.new(0, -6, 0, 0)
        hbar.BackgroundColor3 = Color3.fromRGB(35, 33, 40)
        hbar.BorderSizePixel = 0
        hbar.Visible = false
        hbar.Parent = box
        local hfill = Instance.new("Frame")
        hfill.Name = "HealthFill"
        hfill.Size = UDim2.new(1, 0, 1, 0)
        hfill.BackgroundColor3 = SUCCESS
        hfill.BorderSizePixel = 0
        hfill.Parent = hbar

        local nameTag = Instance.new("TextLabel")
        nameTag.BackgroundTransparency = 1
        nameTag.TextColor3 = TEXT
        nameTag.TextSize = 12
        nameTag.Font = Enum.Font.GothamBold
        nameTag.TextStrokeTransparency = 0
        nameTag.Visible = false
        nameTag.ZIndex = 101
        nameTag.Parent = gui

        local tracer = Instance.new("Frame")
        tracer.AnchorPoint = Vector2.new(0.5, 0.5)
        tracer.BackgroundColor3 = espSettings.Color
        tracer.BorderSizePixel = 0
        tracer.Size = UDim2.new(0, 1, 0, 1)
        tracer.Visible = false
        tracer.ZIndex = 100
        tracer.Parent = gui

        local toolsTag = Instance.new("TextLabel")
        toolsTag.BackgroundTransparency = 1
        toolsTag.TextColor3 = ACCENT
        toolsTag.TextSize = 10
        toolsTag.Font = Enum.Font.Gotham
        toolsTag.TextStrokeTransparency = 0
        toolsTag.TextWrapped = true
        toolsTag.Visible = false
        toolsTag.ZIndex = 101
        toolsTag.Parent = gui

        espDrawings[player] = {
            Box = box, Stroke = stroke, Text = nameTag,
            HealthBar = hbar, HealthFill = hfill, Tracer = tracer,
            Tools = toolsTag
        }
    end

    local function createPlayerButton(player)
        if player == localPlayer then return end
        local b = newButton("  " .. player.Name, playerScroll, CARD, TEXT)
        b.MouseButton1Click:Connect(function()
            pressAnim(b)
            selectedPlayer = player
            tpButton.Text = "TP to: " .. player.Name
            if isSpectating then specButton.Text = "Viewing: " .. player.Name end
        end)
        playerButtonMap[player] = b
    end

    for _, p in ipairs(Players:GetPlayers()) do
        addESP(p)
        createPlayerButton(p)
    end

    Players.PlayerAdded:Connect(function(p)
        addESP(p)
        createPlayerButton(p)
    end)

    Players.PlayerRemoving:Connect(function(p)
        if espDrawings[p] then
            espDrawings[p].Box:Destroy()
            espDrawings[p].Text:Destroy()
            espDrawings[p].Tracer:Destroy()
            if espDrawings[p].Tools then espDrawings[p].Tools:Destroy() end
            espDrawings[p] = nil
        end
        if playerButtonMap[p] then
            playerButtonMap[p]:Destroy()
            playerButtonMap[p] = nil
        end
    end)

    tpButton.MouseButton1Click:Connect(function()
        if selectedPlayer and selectedPlayer.Character then
            local tr = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            local mr = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
            if tr and mr then mr.CFrame = tr.CFrame + Vector3.new(0, 3, 0) end
        end
    end)

    ----------------------------------------
    -- LOCATIONS
    ----------------------------------------
    local locations = {
        {Name = "ATM", Pos = Vector3.new(-172.8, 4.0, 52.3)},
        {Name = "Weed (seed) Farm", Pos = Vector3.new(2121.7, 7.8, 337.5)},
        {Name = "Little Paki", Pos = Vector3.new(-85.7, 4.0, 59.4)},
        {Name = "Gun Store", Pos = Vector3.new(-30277.4, -13.6, 20.4)},
        {Name = "Wheel of Fortune", Pos = Vector3.new(134.2, 4.2, 92.4)},
        {Name = "Admin Roof", Pos = Vector3.new(251.6, 27.9, -77.1)},
        {Name = "Admin Roof 2", Pos = Vector3.new(-16.8, 57.8, 416.3)},
        {Name = "Casino Sell", Pos = Vector3.new(582.9, 4.2, 154.6)},
        {Name = "Spice Dealer", Pos = Vector3.new(185.2, 4.3, 418.8)},
        {Name = "Milk Dealer", Pos = Vector3.new(-22.7, -10.0, -526.4)},
        {Name = "Casino", Pos = Vector3.new(48.2, 4.0, -90.1)},
        {Name = "Apartman 1", Pos = Vector3.new(-0.4, 4.0, 58.0)},
        {Name = "Apartman 2", Pos = Vector3.new(2568.6, 4.3, -120.0)},
        {Name = "Apartman 2 Roof", Pos = Vector3.new(2564.3, 86.3, -89.1)},
        {Name = "Milk Factory", Pos = Vector3.new(2427.4, 4.3, 94.4)},
        {Name = "Black Market Dealer", Pos = Vector3.new(899.1, 4.2, -27.0)},
        {Name = "Car Shop", Pos = Vector3.new(831.7, 4.4, -18.6)},
        {Name = "Box job", Pos = Vector3.new(-132.4, 4.0, 311.3)},
        {Name = "NGF", Pos = Vector3.new(201.3, 4.2, -392.0)}
    }

    local locButtons = {}
    for _, loc in ipairs(locations) do
        local lb = newButton("  " .. loc.Name, locScroll, CARD, TEXT)
        lb.MouseButton1Click:Connect(function()
            pressAnim(lb)
            local char = localPlayer.Character
            local rp = char and char:FindFirstChild("HumanoidRootPart")
            if rp then rp.CFrame = CFrame.new(loc.Pos + Vector3.new(0, 3, 0)) end
        end)
        table.insert(locButtons, {Button = lb, Name = loc.Name:lower()})
    end

    locSearch:GetPropertyChangedSignal("Text"):Connect(function()
        local q = locSearch.Text:lower()
        for _, item in ipairs(locButtons) do
            item.Button.Visible = (q == "" or string.find(item.Name, q))
        end
    end)

    ----------------------------------------
    -- HOME TELEPORT
    ----------------------------------------
    homeBtn.MouseButton1Click:Connect(function()
        local char = localPlayer.Character
        local rp = char and char:FindFirstChild("HumanoidRootPart")
        if rp then rp.CFrame = CFrame.new(Vector3.new(14.4, 50.8, -51.5) + Vector3.new(0, 3, 0)) end
    end)

    ----------------------------------------
    -- SPEC / TOGGLE BUTTONS
    ----------------------------------------
    specButton.MouseButton1Click:Connect(function()
        if not selectedPlayer then return end
        isSpectating = not isSpectating
        if isSpectating then
            specButton.Text = "Viewing: " .. selectedPlayer.Name
            specButton.BackgroundColor3 = Color3.fromRGB(140, 50, 180)
            specButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            specButton.Text = "View Perspective: OFF"
            specButton.BackgroundColor3 = CARD
            specButton.TextColor3 = TEXT
            if localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid") then
                Camera.CameraSubject = localPlayer.Character:FindFirstChildOfClass("Humanoid")
            end
        end
    end)

    flyInput.FocusLost:Connect(function() flySpeed = tonumber(flyInput.Text) or flySpeed end)
    spdInput.FocusLost:Connect(function() walkSpeed = tonumber(spdInput.Text) or walkSpeed end)

    local function toggleFly()
        isFlying = not isFlying
        flyBtn.Text = isFlying and "Fly: ON" or "Fly: OFF"
        flyBtn.BackgroundColor3 = isFlying and SUCCESS or CARD
        flyBtn.TextColor3 = isFlying and Color3.fromRGB(12, 10, 8) or TEXT
        local char = localPlayer.Character
        if char then
            local h = char:FindFirstChildOfClass("Humanoid")
            local rp = char:FindFirstChild("HumanoidRootPart")
            if h then h.PlatformStand = isFlying end
            if not isFlying and rp then
                rp.AssemblyLinearVelocity = Vector3.zero
                rp.AssemblyAngularVelocity = Vector3.zero
            end
            lockedCFrame = nil
        end
    end

    local function toggleSpeed()
        speedEnabled = not speedEnabled
        spdBtn.Text = speedEnabled and "Speed Hack: ON" or "Speed Hack: OFF"
        spdBtn.BackgroundColor3 = speedEnabled and SUCCESS or CARD
        spdBtn.TextColor3 = speedEnabled and Color3.fromRGB(12, 10, 8) or TEXT
        if not speedEnabled and localPlayer.Character then
            local h = localPlayer.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = originalWalkSpeed end
        end
    end

    local function toggleNoclip()
        noclipEnabled = not noclipEnabled
        noclipBtn.Text = noclipEnabled and "Noclip: ON" or "Noclip: OFF"
        noclipBtn.BackgroundColor3 = noclipEnabled and SUCCESS or CARD
        noclipBtn.TextColor3 = noclipEnabled and Color3.fromRGB(12, 10, 8) or TEXT
        if not noclipEnabled and localPlayer.Character then
            for _, part in ipairs(localPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end

    flyBtn.MouseButton1Click:Connect(toggleFly)
    spdBtn.MouseButton1Click:Connect(toggleSpeed)
    noclipBtn.MouseButton1Click:Connect(toggleNoclip)

    espBtn.MouseButton1Click:Connect(function()
        espEnabled = not espEnabled
        espBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
        espBtn.BackgroundColor3 = espEnabled and SUCCESS or CARD
        espBtn.TextColor3 = espEnabled and Color3.fromRGB(12, 10, 8) or TEXT
    end)

    ----------------------------------------
    -- INIT BUTTON
    ----------------------------------------
    local loaded = skipInit
    if not skipInit then
    initBtn.MouseButton1Click:Connect(function()
        pressAnim(initBtn)
        loaded = true
        local fadeTween = TweenService:Create(blur, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 1})
        local shrinkTween = TweenService:Create(lf, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)})
        fadeTween:Play()
        shrinkTween:Play()
        shrinkTween.Completed:Connect(function()
            blur:Destroy()
            mf.Visible = true
            mf.Size = UDim2.new(0, 0, 0, 0)
            mf.Position = UDim2.new(0.5, 0, 0.5, 0)
            TweenService:Create(mf, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 980, 0, 470)}):Play()
        end)
    end)
    else
        blur:Destroy()
    end

    ----------------------------------------
    -- KEYBIND HANDLER
    ----------------------------------------
    if activeKeybindConnection then activeKeybindConnection:Disconnect() end

    local menuOpen = false
    activeKeybindConnection = UserInputService.InputBegan:Connect(function(input, gp)
        if waitingForKey then
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                keybinds[waitingForKey] = input.KeyCode
                if waitingForKey == "Fly" then
                    flyKey.Text = "Fly  [  " .. input.KeyCode.Name .. "  ]"
                elseif waitingForKey == "Speed" then
                    spdKey.Text = "Speed  [  " .. input.KeyCode.Name .. "  ]"
                elseif waitingForKey == "Noclip" then
                    noclipKey.Text = "Noclip  [  " .. input.KeyCode.Name .. "  ]"
                end
                waitingForKey = nil
            end
            return
        end

        if input.KeyCode == Enum.KeyCode.P and loaded and mf then
            menuOpen = not menuOpen
            if menuOpen then
                mf.Visible = true
                TweenService:Create(mf, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 980, 0, 470)}):Play()
            else
                local ca = TweenService:Create(mf, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
                ca:Play()
                ca.Completed:Connect(function()
                    if not menuOpen and mf then mf.Visible = false end
                end)
            end
            return
        end

        if not gp then
            if input.KeyCode == keybinds.Fly then toggleFly()
            elseif input.KeyCode == keybinds.Speed then toggleSpeed()
            elseif input.KeyCode == keybinds.Noclip then toggleNoclip()
            end
        end

        if input.UserInputType == aimbotSettings.AimKey then holdingAim = true end
        if input.KeyCode == Enum.KeyCode.W then keysHeld.W = true end
        if input.KeyCode == Enum.KeyCode.S then keysHeld.S = true end
        if input.KeyCode == Enum.KeyCode.A then keysHeld.A = true end
        if input.KeyCode == Enum.KeyCode.D then keysHeld.D = true end
        if input.KeyCode == Enum.KeyCode.Space then keysHeld.Space = true end
        if input.KeyCode == Enum.KeyCode.LeftShift then keysHeld.LeftShift = true end
    end)
end

----------------------------------------
-- CHARACTER LIFECYCLE
----------------------------------------
local function onCharacterAdded(char)
    cleanupOnDeath()
    setupGUI()
    local humanoid = char:WaitForChild("Humanoid", 5)
    if humanoid then
        originalWalkSpeed = humanoid.WalkSpeed
        humanoid.Died:Connect(function() cleanupOnDeath() end)
    end
end

localPlayer.CharacterAdded:Connect(function(char)
    safeCall("CharacterAdded", function() onCharacterAdded(char) end)
end)

if localPlayer.Character then
    safeCall("InitCharacter", function() onCharacterAdded(localPlayer.Character) end)
end

    UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == aimbotSettings.AimKey then
        holdingAim = false
        currentAimTarget = nil
    end
    if input.KeyCode == Enum.KeyCode.W then keysHeld.W = false end
    if input.KeyCode == Enum.KeyCode.S then keysHeld.S = false end
    if input.KeyCode == Enum.KeyCode.A then keysHeld.A = false end
    if input.KeyCode == Enum.KeyCode.D then keysHeld.D = false end
    if input.KeyCode == Enum.KeyCode.Space then keysHeld.Space = false end
    if input.KeyCode == Enum.KeyCode.LeftShift then keysHeld.LeftShift = false end
end)

----------------------------------------
-- AIMBOT HELPERS
----------------------------------------
local function isTargetValid(player)
    if player == localPlayer then return false end
    if aimbotSettings.TeamCheck and player.Team == localPlayer.Team then return false end
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    return true
end

local function isVisibleCheck(targetPart, character)
    if not aimbotSettings.VisCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {localPlayer.Character, Camera}
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(origin, direction, rp)
    if result and result.Instance then return result.Instance:IsDescendantOf(character) end
    return true
end

local function getClosestTarget()
    local center = Camera.ViewportSize / 2 + aimbotSettings.CenterOffset
    local closest = nil
    local shortest = math.huge
    local myRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    for _, player in ipairs(Players:GetPlayers()) do
        if isTargetValid(player) then
            local char = player.Character
            local aimPart = char and char:FindFirstChild("Head")
            if aimPart then
                local sp, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
                if onScreen then
                    local sd = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if sd <= aimbotSettings.FOV and isVisibleCheck(aimPart, char) then
                        local m = sd
                        if aimbotSettings.TargetMode == "Character" and myRoot then
                            m = (aimPart.Position - myRoot.Position).Magnitude
                        end
                        if m < shortest then
                            shortest = m
                            closest = aimPart
                        end
                    end
                end
            end
        end
    end
    return closest
end

----------------------------------------
-- MAIN RENDER LOOP
----------------------------------------
RunService.RenderStepped:Connect(function(dt)
    pcall(function()
        if isSpectating and selectedPlayer and selectedPlayer.Character then
            local th = selectedPlayer.Character:FindFirstChildOfClass("Humanoid")
            if th then Camera.CameraSubject = th end
        end
    end)

    pcall(function()
        local char = localPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local rootPart = char and char:FindFirstChild("HumanoidRootPart")
        if speedEnabled and humanoid then humanoid.WalkSpeed = walkSpeed end
        if noclipEnabled and char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
        if isFlying and rootPart and Camera then
            if humanoid then humanoid.PlatformStand = true end
            local moveDir = Vector3.zero
            if keysHeld.W then moveDir = moveDir + Camera.CFrame.LookVector end
            if keysHeld.S then moveDir = moveDir - Camera.CFrame.LookVector end
            if keysHeld.A then moveDir = moveDir - Camera.CFrame.RightVector end
            if keysHeld.D then moveDir = moveDir + Camera.CFrame.RightVector end
            if keysHeld.Space then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if keysHeld.LeftShift then moveDir = moveDir - Vector3.new(0, 1, 0) end
            if moveDir.Magnitude > 0 then
                lockedCFrame = nil
                rootPart.AssemblyLinearVelocity = moveDir.Unit * flySpeed
                rootPart.AssemblyAngularVelocity = Vector3.zero
                rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + Camera.CFrame.LookVector)
            else
                if not lockedCFrame then
                    lockedCFrame = CFrame.new(rootPart.Position, rootPart.Position + Camera.CFrame.LookVector)
                end
                rootPart.CFrame = lockedCFrame
                rootPart.AssemblyLinearVelocity = Vector3.zero
                rootPart.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)

    pcall(function()
        local center = Camera.ViewportSize / 2 + aimbotSettings.CenterOffset
        local fovG = screenGui and screenGui:FindFirstChild("FOVCircle")
        if fovG then
            if aimbotSettings.Enabled then
                local sz = aimbotSettings.FOV * 2
                fovG.Size = UDim2.new(0, sz, 0, sz)
                fovG.Position = UDim2.new(0, center.X, 0, center.Y)
                fovG.Visible = true
            else
                fovG.Visible = false
            end
        end
        if aimbotSettings.Enabled and holdingAim then
            if aimbotSettings.AutoSwitch or not currentAimTarget or not currentAimTarget.Parent or not currentAimTarget.Parent:FindFirstChildOfClass("Humanoid") or currentAimTarget.Parent:FindFirstChildOfClass("Humanoid").Health <= 0 or not isVisibleCheck(currentAimTarget, currentAimTarget.Parent) then
                currentAimTarget = getClosestTarget()
            end
            if currentAimTarget then
                if aimbotSettings.OverrideCam then Camera.CameraType = Enum.CameraType.Scriptable end
                local tcf = CFrame.new(Camera.CFrame.Position, currentAimTarget.Position)
                if aimbotSettings.Smoothness >= 1 then
                    Camera.CFrame = tcf
                else
                    Camera.CFrame = Camera.CFrame:Lerp(tcf, aimbotSettings.Smoothness)
                end
            end
        else
            currentAimTarget = nil
        end
    end)

    pcall(function()
        for player, views in pairs(espDrawings) do
            if not player.Character then
                espDrawings[player] = nil
            else
                local pChar = player.Character
                local pRoot = pChar and pChar:FindFirstChild("HumanoidRootPart")
                local pHum = pChar and pChar:FindFirstChildOfClass("Humanoid")
                if espEnabled and pRoot and pHum and pHum.Health > 0 then
                    local vec, onScreen = Camera:WorldToViewportPoint(pRoot.Position)
                    if onScreen then
                        local rp2, _ = Camera:WorldToViewportPoint(pRoot.Position + Vector3.new(0, 3, 0))
                        local lp2, _ = Camera:WorldToViewportPoint(pRoot.Position - Vector3.new(0, 3, 0))
                        local h = math.abs(rp2.Y - lp2.Y)
                        local w = h / 2
                        views.Box.Size = UDim2.new(0, w, 0, h)
                        views.Box.Position = UDim2.new(0, vec.X - w / 2, 0, vec.Y - h / 2)
                        views.Box.Visible = true
                        views.Stroke.Color = espSettings.Color

                        if espSettings.Names then
                            views.Text.Text = player.Name
                            views.Text.Position = UDim2.new(0, vec.X - 50, 0, (vec.Y - h / 2) - 20)
                            views.Text.Size = UDim2.new(0, 100, 0, 20)
                            views.Text.Visible = true
                        else
                            views.Text.Visible = false
                        end

                        if espSettings.HealthBar then
                            local hp = math.clamp(pHum.Health / pHum.MaxHealth, 0, 1)
                            views.HealthBar.Visible = true
                            views.HealthFill.Size = UDim2.new(1, 0, hp, 0)
                            views.HealthFill.Position = UDim2.new(0, 0, 1 - hp, 0)
                            views.HealthFill.BackgroundColor3 = Color3.fromRGB(20 + 65 * hp, 20 + 150 * hp, 20 + 65 * hp)
                        else
                            views.HealthBar.Visible = false
                        end

                        if espSettings.Tracers then
                            local vs = Camera.ViewportSize
                            local bc = Vector2.new(vs.X / 2, vs.Y)
                            local tp = Vector2.new(vec.X, vec.Y)
                            local dist = (tp - bc).Magnitude
                            local mid = bc:Lerp(tp, 0.5)
                            views.Tracer.Size = UDim2.new(0, 1, 0, dist)
                            views.Tracer.Position = UDim2.new(0, mid.X, 0, mid.Y)
                            views.Tracer.Rotation = math.deg(math.atan2(tp.Y - bc.Y, tp.X - bc.X)) - 90
                            views.Tracer.BackgroundColor3 = espSettings.Color
                            views.Tracer.Visible = true
                        else
                            views.Tracer.Visible = false
                        end

                        if espSettings.ShowTools then
                            local toolNames = {}
                            local backpack = player:FindFirstChild("Backpack")
                            if backpack then
                                for _, item in ipairs(backpack:GetChildren()) do
                                    if item:IsA("Tool") then
                                        table.insert(toolNames, item.Name)
                                    end
                                end
                            end
                            local charTools = {}
                            if pChar then
                                for _, item in ipairs(pChar:GetChildren()) do
                                    if item:IsA("Tool") then
                                        table.insert(charTools, item.Name)
                                    end
                                end
                            end
                            for _, name in ipairs(charTools) do
                                table.insert(toolNames, 1, name)
                            end
                            if #toolNames > 0 then
                                views.Tools.Text = table.concat(toolNames, ", ")
                                views.Tools.Position = UDim2.new(0, vec.X - 60, 0, (vec.Y + h / 2) + 4)
                                views.Tools.Size = UDim2.new(0, 120, 0, 14)
                                views.Tools.Visible = true
                            else
                                views.Tools.Visible = false
                            end
                        else
                            views.Tools.Visible = false
                        end
                    else
                        views.Box.Visible = false
                        views.Text.Visible = false
                        views.HealthBar.Visible = false
                        views.Tracer.Visible = false
                        views.Tools.Visible = false
                    end
                else
                    views.Box.Visible = false
                    views.Text.Visible = false
                    views.HealthBar.Visible = false
                    views.Tracer.Visible = false
                    views.Tools.Visible = false
                end
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and not espDrawings[player] then
                addESP(player)
            end
        end
    end)
end)
