-- BBAC V0.1.0
-- Premium black UI + bypass scaffold
-- Executor required for hookmetamethod / getrawmetatable / getconnections

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- THEME
-- ============================================================
local Theme = {
    bg          = Color3.fromRGB(10, 10, 12),
    panel       = Color3.fromRGB(16, 16, 20),
    panelAlt    = Color3.fromRGB(22, 22, 27),
    stroke      = Color3.fromRGB(38, 38, 46),
    text        = Color3.fromRGB(230, 230, 235),
    textDim     = Color3.fromRGB(120, 120, 130),
    accent      = Color3.fromRGB(0, 200, 220),
    accentDim   = Color3.fromRGB(0, 120, 135),
    danger      = Color3.fromRGB(220, 70, 80),
    ok          = Color3.fromRGB(80, 200, 130),
    fontMono    = Enum.Font.Code,
    fontUI      = Enum.Font.Gotham,
    fontUIBold  = Enum.Font.GothamBold,
}

-- ============================================================
-- STATE
-- ============================================================
local State = {
    active = false,
    log = {},
    methods = {
        humanoid = {
            { id = "velocity_phantom", name = "Velocity Phantom", desc = "Desync позиции: сервер видит легальную траекторию", on = false },
            { id = "property_spoof",   name = "Property Spoof",   desc = "Спуф WalkSpeed / JumpPower для детекторов",        on = false },
            { id = "noclip",           name = "Noclip",           desc = "Отключение коллизий персонажа",                    on = false },
            { id = "fly",              name = "Fly",              desc = "Вертикальное движение без гравитации",              on = false },
        },
        alt = {
            { id = "script_purge",     name = "Script Purge",     desc = "Удаление локального античита + реинжект",           on = false },
            { id = "remote_blackhole", name = "Remote Blackhole", desc = "Блок отчётов через FireServer / InvokeServer",       on = false },
            { id = "connection_sever", name = "Connection Sever", desc = "Disable соединений античита",                        on = false },
            { id = "function_hook",    name = "Function Hook",    desc = "Замена Detect / Flag / Report / Kick",               on = false },
        },
    },
    addons = {},
}

local function log(msg)
    table.insert(State.log, string.format("[%s] %s", os.date("%H:%M:%S"), msg))
    if #State.log > 200 then table.remove(State.log, 1) end
end

-- ============================================================
-- UI HELPERS
-- ============================================================
local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.stroke
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function pad(parent, p)
    local u = Instance.new("UIPadding")
    u.PaddingLeft = UDim.new(0, p)
    u.PaddingRight = UDim.new(0, p)
    u.PaddingTop = UDim.new(0, p)
    u.PaddingBottom = UDim.new(0, p)
    u.Parent = parent
    return u
end

local function label(parent, text, size, color, font, xAlign)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextSize = size or 13
    l.TextColor3 = color or Theme.text
    l.Font = font or Theme.fontUI
    l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

-- ============================================================
-- LAYOUT — adaptive
-- ============================================================
local cam = workspace.CurrentCamera
local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local isNarrow = vp.X < 560

local WIN_W = math.clamp(vp.X - 40, 320, 620)
local WIN_H = math.clamp(vp.Y - 80, 380, 460)
if isNarrow then
    WIN_W = math.clamp(vp.X - 20, 300, 620)
    WIN_H = math.clamp(vp.Y - 40, 360, 520)
end

local SIDEBAR_W = isNarrow and 0 or 150
local SIDEBAR_H = isNarrow and 40 or 0

-- ============================================================
-- ROOT
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "BBAC_V010"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.new(0, WIN_W, 0, WIN_H)
root.Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2)
root.BackgroundColor3 = Theme.bg
root.BorderSizePixel = 0
root.Active = true
root.Draggable = not isMobile
root.Parent = gui
corner(root, 12)
stroke(root, Theme.stroke, 1)

-- collapsed dot
local dot = Instance.new("TextButton")
dot.Name = "Collapsed"
dot.Size = UDim2.new(0, 44, 0, 44)
dot.Position = UDim2.new(1, -56, 1, -56)
dot.BackgroundColor3 = Theme.panel
dot.Text = "B"
dot.TextColor3 = Theme.accent
dot.TextSize = 16
dot.Font = Theme.fontUIBold
dot.BorderSizePixel = 0
dot.Visible = false
dot.Active = true
dot.Draggable = true
dot.Parent = gui
corner(dot, 22)
stroke(dot, Theme.accentDim, 1)

-- title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundTransparency = 1
titleBar.Parent = root

local titleLbl = label(titleBar, "BBAC", 15, Theme.text, Theme.fontUIBold)
titleLbl.Size = UDim2.new(0, 80, 1, 0)
titleLbl.Position = UDim2.new(0, 18, 0, 0)

local verLbl = label(titleBar, "V0.1.0", 11, Theme.textDim, Theme.fontMono)
verLbl.Size = UDim2.new(0, 80, 1, 0)
verLbl.Position = UDim2.new(0, 62, 0, 0)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 8, 0, 8)
statusDot.Position = UDim2.new(1, -150, 0.5, -4)
statusDot.BackgroundColor3 = Theme.textDim
statusDot.BorderSizePixel = 0
statusDot.Parent = titleBar
corner(statusDot, 4)

local statusLbl = label(titleBar, "inactive", 11, Theme.textDim, Theme.fontMono)
statusLbl.Size = UDim2.new(0, 80, 1, 0)
statusLbl.Position = UDim2.new(1, -136, 0, 0)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -38, 0, 6)
closeBtn.BackgroundColor3 = Theme.panelAlt
closeBtn.Text = "×"
closeBtn.TextColor3 = Theme.textDim
closeBtn.TextSize = 18
closeBtn.Font = Theme.fontUI
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
corner(closeBtn, 6)

local function collapse()
    root.Visible = false
    dot.Visible = true
end

local function expand()
    root.Visible = true
    dot.Visible = false
end

closeBtn.MouseButton1Click:Connect(collapse)
dot.MouseButton1Click:Connect(expand)

-- divider
local div = Instance.new("Frame")
div.Size = UDim2.new(1, -36, 0, 1)
div.Position = UDim2.new(0, 18, 0, 40)
div.BackgroundColor3 = Theme.stroke
div.BorderSizePixel = 0
div.Parent = root

-- sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, SIDEBAR_W, isNarrow and 0 or 1, isNarrow and SIDEBAR_H or -52)
sidebar.Position = UDim2.new(0, isNarrow and 18 or 18, isNarrow and 48 or 48, isNarrow and -4 or 0)
if isNarrow then
    sidebar.Size = UDim2.new(1, -36, 0, SIDEBAR_H)
    sidebar.Position = UDim2.new(0, 18, 0, 48)
end
sidebar.BackgroundTransparency = 1
sidebar.ClipsDescendants = false
sidebar.Parent = root

-- content
local content = Instance.new("Frame")
if isNarrow then
    content.Size = UDim2.new(1, -36, 1, -(48 + SIDEBAR_H + 16))
    content.Position = UDim2.new(0, 18, 0, 48 + SIDEBAR_H + 8)
else
    content.Size = UDim2.new(1, -(SIDEBAR_W + 54), 1, -52)
    content.Position = UDim2.new(0, SIDEBAR_W + 36, 0, 48)
end
content.BackgroundTransparency = 1
content.Parent = root

-- ============================================================
-- TABS
-- ============================================================
local tabs = {}
local pages = {}
local currentTab = nil
local tabCounter = 0

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
if isNarrow then
    sidebarLayout.FillDirection = Enum.FillDirection.Horizontal
    sidebarLayout.Padding = UDim.new(0, 6)
    sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    sidebarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
else
    sidebarLayout.FillDirection = Enum.FillDirection.Vertical
    sidebarLayout.Padding = UDim.new(0, 4)
end
sidebarLayout.Parent = sidebar

local function makeTab(id, name)
    tabCounter = tabCounter + 1

    local btn = Instance.new("TextButton")
    if isNarrow then
        btn.Size = UDim2.new(0, 90, 0, 30)
    else
        btn.Size = UDim2.new(1, 0, 0, 34)
    end
    btn.BackgroundColor3 = Theme.panel
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.LayoutOrder = tabCounter
    btn.Parent = sidebar
    corner(btn, 8)

    local ind = Instance.new("Frame")
    if isNarrow then
        ind.Size = UDim2.new(1, -12, 0, 2)
        ind.Position = UDim2.new(0, 6, 1, -3)
    else
        ind.Size = UDim2.new(0, 2, 0, 16)
        ind.Position = UDim2.new(0, 0, 0.5, -8)
    end
    ind.BackgroundColor3 = Theme.accent
    ind.BorderSizePixel = 0
    ind.Visible = false
    ind.Parent = btn
    corner(ind, 1)

    local lbl = label(btn, name, 12, Theme.textDim, Theme.fontUI, Enum.TextXAlignment.Center)
    lbl.Size = UDim2.new(1, -12, 1, 0)
    lbl.Position = UDim2.new(0, 6, 0, 0)

    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = content

    tabs[id] = { btn = btn, ind = ind, lbl = lbl, page = page, name = name }
    pages[id] = page

    btn.MouseButton1Click:Connect(function()
        for tid, t in pairs(tabs) do
            t.ind.Visible = false
            t.lbl.TextColor3 = Theme.textDim
            t.page.Visible = false
            t.btn.BackgroundTransparency = 1
        end
        ind.Visible = true
        lbl.TextColor3 = Theme.text
        btn.BackgroundTransparency = 0.9
        page.Visible = true
        currentTab = id
    end)

    return page
end

local homePage = makeTab("home", "Home")
local acPage   = makeTab("ac", "AC")
local addPage  = makeTab("addons", "Addons")

-- ============================================================
-- HOME
-- ============================================================
local homeScroll = Instance.new("ScrollingFrame")
homeScroll.Size = UDim2.new(1, 0, 1, 0)
homeScroll.BackgroundTransparency = 1
homeScroll.BorderSizePixel = 0
homeScroll.ScrollBarThickness = 3
homeScroll.ScrollBarImageColor3 = Theme.stroke
homeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
homeScroll.Parent = homePage

local profileCard = Instance.new("Frame")
profileCard.Size = UDim2.new(1, 0, 0, 96)
profileCard.BackgroundColor3 = Theme.panel
profileCard.BorderSizePixel = 0
profileCard.Parent = homeScroll
corner(profileCard, 10)
stroke(profileCard, Theme.stroke, 1)

local avatar = Instance.new("ImageLabel")
avatar.Size = UDim2.new(0, 64, 0, 64)
avatar.Position = UDim2.new(0, 16, 0.5, -32)
avatar.BackgroundColor3 = Theme.panelAlt
avatar.BorderSizePixel = 0
avatar.Parent = profileCard
corner(avatar, 8)

local pName = label(profileCard, LocalPlayer.Name, 16, Theme.text, Theme.fontUIBold)
pName.Size = UDim2.new(1, -110, 0, 22)
pName.Position = UDim2.new(0, 96, 0, 22)

local pId = label(profileCard, "id " .. tostring(LocalPlayer.UserId), 11, Theme.textDim, Theme.fontMono)
pId.Size = UDim2.new(1, -110, 0, 18)
pId.Position = UDim2.new(0, 96, 0, 46)

local pStatus = label(profileCard, "status: idle", 11, Theme.textDim, Theme.fontMono)
pStatus.Size = UDim2.new(1, -110, 0, 18)
pStatus.Position = UDim2.new(0, 96, 0, 64)

task.spawn(function()
    local ok, img = pcall(function()
        return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
    end)
    if ok and img then avatar.Image = img end
end)

local listHeader = label(homeScroll, "LOADED FUNCTIONS", 11, Theme.textDim, Theme.fontMono)
listHeader.Size = UDim2.new(1, 0, 0, 18)
listHeader.Position = UDim2.new(0, 2, 0, 108)

local funcList = Instance.new("ScrollingFrame")
funcList.Size = UDim2.new(1, 0, 0, 220)
funcList.Position = UDim2.new(0, 0, 0, 130)
funcList.BackgroundColor3 = Theme.panel
funcList.BorderSizePixel = 0
funcList.ScrollBarThickness = 3
funcList.ScrollBarImageColor3 = Theme.stroke
funcList.CanvasSize = UDim2.new(0, 0, 0, 0)
funcList.Parent = homeScroll
corner(funcList, 10)
stroke(funcList, Theme.stroke, 1)

local funcLayout = Instance.new("UIListLayout")
funcLayout.SortOrder = Enum.SortOrder.LayoutOrder
funcLayout.Padding = UDim.new(0, 1)
funcLayout.Parent = funcList
pad(funcList, 6)

local function refreshFuncList()
    for _, c in ipairs(funcList:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local i = 0
    for _, group in pairs(State.methods) do
        for _, m in ipairs(group) do
            i = i + 1
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -12, 0, 26)
            row.BackgroundTransparency = 1
            row.LayoutOrder = i
            row.Parent = funcList

            local nm = label(row, m.name, 12, Theme.text, Theme.fontUI)
            nm.Size = UDim2.new(0, 200, 1, 0)
            nm.Position = UDim2.new(0, 6, 0, 0)

            local st = label(row, m.on and "on" or "off", 11, m.on and Theme.ok or Theme.textDim, Theme.fontMono, Enum.TextXAlignment.Right)
            st.Size = UDim2.new(0, 60, 1, 0)
            st.Position = UDim2.new(1, -66, 0, 0)
        end
    end
    funcList.CanvasSize = UDim2.new(0, 0, 0, funcLayout.AbsoluteContentSize.Y + 12)
end

homeScroll.CanvasSize = UDim2.new(0, 0, 0, 130 + 220 + 8)

-- ============================================================
-- AC
-- ============================================================
local function makeCategory(parent, titleText, key)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 0)
    wrap.AutomaticSize = Enum.AutomaticSize.Y
    wrap.BackgroundTransparency = 1
    wrap.Parent = parent

    local hdr = label(wrap, titleText, 11, Theme.textDim, Theme.fontMono)
    hdr.Size = UDim2.new(1, 0, 0, 18)
    hdr.Position = UDim2.new(0, 2, 0, 0)

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 0, 0)
    list.Position = UDim2.new(0, 0, 0, 22)
    list.AutomaticSize = Enum.AutomaticSize.Y
    list.BackgroundTransparency = 1
    list.Parent = wrap

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = list

    for i, m in ipairs(State.methods[key]) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 56)
        card.BackgroundColor3 = Theme.panel
        card.BorderSizePixel = 0
        card.LayoutOrder = i
        card.Parent = list
        corner(card, 10)
        stroke(card, Theme.stroke, 1)

        local nm = label(card, m.name, 13, Theme.text, Theme.fontUIBold)
        nm.Size = UDim2.new(1, -80, 0, 18)
        nm.Position = UDim2.new(0, 14, 0, 10)

        local ds = label(card, m.desc, 11, Theme.textDim, Theme.fontUI)
        ds.Size = UDim2.new(1, -80, 0, 16)
        ds.Position = UDim2.new(0, 14, 0, 30)
        ds.TextTruncate = Enum.TextTruncate.AtEnd

        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(0, 48, 0, 24)
        toggle.Position = UDim2.new(1, -60, 0.5, -12)
        toggle.BackgroundColor3 = Theme.panelAlt
        toggle.Text = m.on and "ON" or "OFF"
        toggle.TextColor3 = m.on and Theme.ok or Theme.textDim
        toggle.TextSize = 11
        toggle.Font = Theme.fontMono
        toggle.BorderSizePixel = 0
        toggle.Parent = card
        corner(toggle, 6)

        toggle.MouseButton1Click:Connect(function()
            m.on = not m.on
            toggle.Text = m.on and "ON" or "OFF"
            toggle.TextColor3 = m.on and Theme.ok or Theme.textDim
            toggle.BackgroundColor3 = m.on and Theme.accentDim or Theme.panelAlt
            log(string.format("%s -> %s", m.name, m.on and "on" or "off"))
            refreshFuncList()
            local ok, err = pcall(function()
                local Bypass = _G.BBAC_Bypass
                if Bypass and Bypass.onToggle then Bypass.onToggle(m.id, m.on) end
            end)
            if not ok then log("toggle err: " .. tostring(err)) end
        end)
    end

    return wrap
end

local acScroll = Instance.new("ScrollingFrame")
acScroll.Size = UDim2.new(1, 0, 1, -46)
acScroll.Position = UDim2.new(0, 0, 0, 0)
acScroll.BackgroundTransparency = 1
acScroll.BorderSizePixel = 0
acScroll.ScrollBarThickness = 3
acScroll.ScrollBarImageColor3 = Theme.stroke
acScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
acScroll.Parent = acPage

local acLayout = Instance.new("UIListLayout")
acLayout.SortOrder = Enum.SortOrder.LayoutOrder
acLayout.Padding = UDim.new(0, 16)
acLayout.Parent = acScroll

makeCategory(acScroll, "HUMANOID — speed / fly / noclip", "humanoid").LayoutOrder = 1
makeCategory(acScroll, "ALT — server authority bypass", "alt").LayoutOrder = 2

acLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    acScroll.CanvasSize = UDim2.new(0, 0, 0, acLayout.AbsoluteContentSize.Y + 12)
end)

local activateBtn = Instance.new("TextButton")
activateBtn.Size = UDim2.new(1, 0, 0, 36)
activateBtn.Position = UDim2.new(0, 0, 1, -36)
activateBtn.BackgroundColor3 = Theme.accent
activateBtn.Text = "ACTIVATE"
activateBtn.TextColor3 = Theme.bg
activateBtn.TextSize = 13
activateBtn.Font = Theme.fontUIBold
activateBtn.BorderSizePixel = 0
activateBtn.Parent = acPage
corner(activateBtn, 8)

activateBtn.MouseButton1Click:Connect(function()
    State.active = not State.active
    if State.active then
        activateBtn.Text = "ACTIVE"
        activateBtn.BackgroundColor3 = Theme.ok
        statusDot.BackgroundColor3 = Theme.ok
        statusLbl.Text = "active"
        statusLbl.TextColor3 = Theme.ok
        pStatus.Text = "status: active"
        pStatus.TextColor3 = Theme.ok
        log("bypass activated")
        local Bypass = _G.BBAC_Bypass
        if Bypass and Bypass.activate then pcall(Bypass.activate) end
    else
        activateBtn.Text = "ACTIVATE"
        activateBtn.BackgroundColor3 = Theme.accent
        statusDot.BackgroundColor3 = Theme.textDim
        statusLbl.Text = "inactive"
        statusLbl.TextColor3 = Theme.textDim
        pStatus.Text = "status: idle"
        pStatus.TextColor3 = Theme.textDim
        log("bypass deactivated")
        local Bypass = _G.BBAC_Bypass
        if Bypass and Bypass.deactivate then pcall(Bypass.deactivate) end
    end
end)

-- ============================================================
-- ADDONS
-- ============================================================
local addHint = label(addPage, "Paste addon source. Runs sandboxed.", 11, Theme.textDim, Theme.fontUI)
addHint.Size = UDim2.new(1, 0, 0, 24)
addHint.Position = UDim2.new(0, 2, 0, 0)
addHint.TextWrapped = true

local addBox = Instance.new("TextBox")
addBox.Size = UDim2.new(1, 0, 0, 80)
addBox.Position = UDim2.new(0, 0, 0, 30)
addBox.BackgroundColor3 = Theme.panel
addBox.BorderSizePixel = 0
addBox.Text = ""
addBox.PlaceholderText = "-- addon source here"
addBox.TextColor3 = Theme.text
addBox.PlaceholderColor3 = Theme.textDim
addBox.TextSize = 12
addBox.Font = Theme.fontMono
addBox.TextXAlignment = Enum.TextXAlignment.Left
addBox.TextYAlignment = Enum.TextYAlignment.Top
addBox.ClearTextOnFocus = false
addBox.MultiLine = true
addBox.Parent = addPage
corner(addBox, 10)
stroke(addBox, Theme.stroke, 1)
pad(addBox, 8)

local loadBtn = Instance.new("TextButton")
loadBtn.Size = UDim2.new(0, 120, 0, 32)
loadBtn.Position = UDim2.new(0, 0, 0, 118)
loadBtn.BackgroundColor3 = Theme.panelAlt
loadBtn.Text = "LOAD ADDON"
loadBtn.TextColor3 = Theme.text
loadBtn.TextSize = 12
loadBtn.Font = Theme.fontUIBold
loadBtn.BorderSizePixel = 0
loadBtn.Parent = addPage
corner(loadBtn, 8)
stroke(loadBtn, Theme.stroke, 1)

local addLog = Instance.new("ScrollingFrame")
addLog.Size = UDim2.new(1, 0, 1, -158)
addLog.Position = UDim2.new(0, 0, 0, 158)
addLog.BackgroundColor3 = Theme.panel
addLog.BorderSizePixel = 0
addLog.ScrollBarThickness = 3
addLog.ScrollBarImageColor3 = Theme.stroke
addLog.CanvasSize = UDim2.new(0, 0, 0, 0)
addLog.Parent = addPage
corner(addLog, 10)
stroke(addLog, Theme.stroke, 1)

local addLogLabel = Instance.new("TextLabel")
addLogLabel.BackgroundTransparency = 1
addLogLabel.Size = UDim2.new(1, -16, 0, 0)
addLogLabel.Position = UDim2.new(0, 8, 0, 8)
addLogLabel.Text = ""
addLogLabel.TextColor3 = Theme.textDim
addLogLabel.TextSize = 11
addLogLabel.Font = Theme.fontMono
addLogLabel.TextXAlignment = Enum.TextXAlignment.Left
addLogLabel.TextYAlignment = Enum.TextYAlignment.Top
addLogLabel.AutomaticSize = Enum.AutomaticSize.Y
addLogLabel.Parent = addLog

local function addonLog(msg)
    addLogLabel.Text = addLogLabel.Text .. "\n" .. msg
    addLog.CanvasSize = UDim2.new(0, 0, 0, addLogLabel.AbsoluteSize.Y + 16)
    addLog.CanvasPosition = Vector2.new(0, math.max(0, addLogLabel.AbsoluteSize.Y - addLog.AbsoluteSize.Y + 16))
end

loadBtn.MouseButton1Click:Connect(function()
    local src = addBox.Text
    if #src < 3 then addonLog("addon: empty source"); return end
    local ok, fn = pcall(function()
        return loadstring(src)
    end)
    if not ok or not fn then
        addonLog("addon: compile error -> " .. tostring(fn))
        return
    end
    local id = "addon_" .. tostring(#State.addons + 1)
    local env = setmetatable({
        BBAC = {
            register = function(name, cb)
                table.insert(State.addons, { id = id, name = name, cb = cb })
                addonLog("registered: " .. tostring(name))
            end,
            log = addonLog,
            toggle = function(mid, on)
                for _, group in pairs(State.methods) do
                    for _, m in ipairs(group) do
                        if m.id == mid then m.on = on; refreshFuncList(); return end
                    end
                end
            end,
        },
        print = addonLog,
    }, { __index = _G })
    local ok2, err = pcall(fn, env)
    if not ok2 then addonLog("addon: runtime error -> " .. tostring(err)); return end
    table.insert(State.addons, { id = id, name = "anonymous", cb = nil })
    addonLog("loaded: " .. id)
end)

-- ============================================================
-- INIT
-- ============================================================
tabs.home.btn.MouseButton1Click:Fire()
refreshFuncList()
log("BBAC V0.1.0 initialized")

_G.BBAC_Bypass = _G.BBAC_Bypass or {}
