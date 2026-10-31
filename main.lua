-- BBAC V0.1.0
-- Wizard-driven bypass scaffold
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
    bg        = Color3.fromRGB(10, 10, 12),
    panel     = Color3.fromRGB(16, 16, 20),
    panelAlt  = Color3.fromRGB(22, 22, 27),
    stroke    = Color3.fromRGB(38, 38, 46),
    text      = Color3.fromRGB(230, 230, 235),
    textDim   = Color3.fromRGB(120, 120, 130),
    accent    = Color3.fromRGB(0, 200, 220),
    accentDim = Color3.fromRGB(0, 120, 135),
    ok        = Color3.fromRGB(80, 200, 130),
    danger    = Color3.fromRGB(220, 70, 80),
    fontMono  = Enum.Font.Code,
    fontUI    = Enum.Font.Gotham,
    fontBold  = Enum.Font.GothamBold,
}

-- ============================================================
-- STATE
-- ============================================================
local State = {
    active = false,
    log = {},
    methods = {
        humanoid = {
            { id = "velocity_phantom", name = "Velocity Phantom", desc = "Desync позиции: сервер видит легальную траекторию" },
            { id = "property_spoof",   name = "Property Spoof",   desc = "Спуф WalkSpeed / JumpPower для детекторов" },
            { id = "noclip",           name = "Noclip",           desc = "Отключение коллизий персонажа" },
            { id = "fly",              name = "Fly",              desc = "Вертикальное движение без гравитации" },
        },
        alt = {
            { id = "script_purge",     name = "Script Purge",     desc = "Удаление локального античита + реинжект" },
            { id = "remote_blackhole", name = "Remote Blackhole", desc = "Блок отчётов через FireServer / InvokeServer" },
            { id = "connection_sever", name = "Connection Sever", desc = "Disable соединений античита" },
            { id = "function_hook",    name = "Function Hook",    desc = "Замена Detect / Flag / Report / Kick" },
        },
    },
    addons = {},
    selected = {
        category = nil,
        method = nil,
        addon = nil,
    },
}

local function log(msg)
    table.insert(State.log, string.format("[%s] %s", os.date("%H:%M:%S"), msg))
    if #State.log > 200 then table.remove(State.log, 1) end
end

-- ============================================================
-- HELPERS
-- ============================================================
local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = p
    return c
end

local function stroke(p, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.stroke
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

local function pad(p, n)
    local u = Instance.new("UIPadding")
    u.PaddingLeft = UDim.new(0, n)
    u.PaddingRight = UDim.new(0, n)
    u.PaddingTop = UDim.new(0, n)
    u.PaddingBottom = UDim.new(0, n)
    u.Parent = p
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
-- LAYOUT
-- ============================================================
local cam = workspace.CurrentCamera
local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local isNarrow = vp.X < 560

local WIN_W = math.clamp(vp.X - 40, 340, 480)
local WIN_H = math.clamp(vp.Y - 80, 440, 520)
if isNarrow then
    WIN_W = math.clamp(vp.X - 20, 300, 480)
    WIN_H = math.clamp(vp.Y - 40, 420, 560)
end

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
root.Size = UDim2.new(0, WIN_W, 0, WIN_H)
root.Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
root.BackgroundColor3 = Theme.bg
root.BorderSizePixel = 0
root.Active = true
root.Draggable = not isMobile
root.Parent = gui
corner(root, 12)
stroke(root, Theme.stroke, 1)

-- collapsed dot
local dot = Instance.new("TextButton")
dot.Size = UDim2.new(0, 44, 0, 44)
dot.Position = UDim2.new(1, -56, 1, -56)
dot.BackgroundColor3 = Theme.panel
dot.Text = "B"
dot.TextColor3 = Theme.accent
dot.TextSize = 16
dot.Font = Theme.fontBold
dot.BorderSizePixel = 0
dot.Visible = false
dot.Draggable = true
dot.Parent = gui
corner(dot, 22)
stroke(dot, Theme.accentDim, 1)

-- title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundTransparency = 1
titleBar.Parent = root

local titleLbl = label(titleBar, "BBAC", 15, Theme.text, Theme.fontBold)
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

local statusLbl = label(titleBar, "idle", 11, Theme.textDim, Theme.fontMono)
statusLbl.Size = UDim2.new(0, 80, 1, 0)
statusLbl.Position = UDim2.new(1, -136, 0, 0)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -38, 0, 6)
closeBtn.BackgroundColor3 = Theme.panelAlt
closeBtn.Text = "×"
closeBtn.TextColor3 = Theme.textDim
closeBtn.TextSize = 18
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
corner(closeBtn, 6)

closeBtn.MouseButton1Click:Connect(function()
    root.Visible = false
    dot.Visible = true
end)
dot.MouseButton1Click:Connect(function()
    root.Visible = true
    dot.Visible = false
end)

-- divider
local div = Instance.new("Frame")
div.Size = UDim2.new(1, -36, 0, 1)
div.Position = UDim2.new(0, 18, 0, 40)
div.BackgroundColor3 = Theme.stroke
div.BorderSizePixel = 0
div.Parent = root

-- wizard content
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -36, 1, -52)
content.Position = UDim2.new(0, 18, 0, 48)
content.BackgroundTransparency = 1
content.Parent = root

-- ============================================================
-- STAGES
-- ============================================================
local stages = {}
local stageOrder = {"category", "method", "addon", "inject", "success"}

local function makeStage(id, titleText, subtitle)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.Visible = false
    f.Parent = content

    local t = label(f, titleText, 14, Theme.text, Theme.fontBold)
    t.Size = UDim2.new(1, 0, 0, 22)
    t.Position = UDim2.new(0, 0, 0, 0)

    local st = label(f, subtitle or "", 10, Theme.textDim, Theme.fontMono)
    st.Size = UDim2.new(1, 0, 0, 14)
    st.Position = UDim2.new(0, 0, 0, 24)

    stages[id] = { frame = f }
    return f
end

local function showStage(id)
    for _, s in pairs(stages) do s.frame.Visible = false end
    if stages[id] then stages[id].frame.Visible = true end
end

local function makeBackBtn(parent, onClick)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 70, 0, 28)
    b.Position = UDim2.new(0, 0, 1, -28)
    b.BackgroundColor3 = Theme.panelAlt
    b.Text = "← back"
    b.TextColor3 = Theme.textDim
    b.TextSize = 11
    b.Font = Theme.fontMono
    b.BorderSizePixel = 0
    b.Parent = parent
    corner(b, 6)
    stroke(b, Theme.stroke, 1)
    b.MouseButton1Click:Connect(onClick)
    return b
end

-- ============================================================
-- STAGE 1: CATEGORY
-- ============================================================
local catFrame = makeStage("category", "Выберите категорию", "step 1 / 3")

local catList = Instance.new("Frame")
catList.Size = UDim2.new(1, 0, 1, -90)
catList.Position = UDim2.new(0, 0, 0, 46)
catList.BackgroundTransparency = 1
catList.Parent = catFrame

local catLayout = Instance.new("UIListLayout")
catLayout.SortOrder = Enum.SortOrder.LayoutOrder
catLayout.Padding = UDim.new(0, 8)
catLayout.Parent = catList

local categories = {
    { id = "humanoid", name = "HUMANOID", desc = "speed / fly / noclip / property spoof" },
    { id = "alt",      name = "ALT",      desc = "server authority bypass: purge / blackhole / hook" },
}

for i, cat in ipairs(categories) do
    local card = Instance.new("TextButton")
    card.Size = UDim2.new(1, 0, 0, 60)
    card.BackgroundColor3 = Theme.panel
    card.BorderSizePixel = 0
    card.Text = ""
    card.LayoutOrder = i
    card.Parent = catList
    corner(card, 10)
    stroke(card, Theme.stroke, 1)

    local nm = label(card, cat.name, 13, Theme.text, Theme.fontBold)
    nm.Size = UDim2.new(1, -24, 0, 18)
    nm.Position = UDim2.new(0, 14, 0, 12)

    local ds = label(card, cat.desc, 11, Theme.textDim, Theme.fontUI)
    ds.Size = UDim2.new(1, -24, 0, 16)
    ds.Position = UDim2.new(0, 14, 0, 30)

    card.MouseButton1Click:Connect(function()
        State.selected.category = cat.id
        log("category: " .. cat.id)
        buildMethodStage()
        showStage("method")
    end)
end

-- ============================================================
-- STAGE 2: METHOD
-- ============================================================
local methodFrame = makeStage("method", "Выберите метод", "step 2 / 3")

local methodList = Instance.new("ScrollingFrame")
methodList.Size = UDim2.new(1, 0, 1, -120)
methodList.Position = UDim2.new(0, 0, 0, 46)
methodList.BackgroundTransparency = 1
methodList.BorderSizePixel = 0
methodList.ScrollBarThickness = 3
methodList.ScrollBarImageColor3 = Theme.stroke
methodList.CanvasSize = UDim2.new(0, 0, 0, 0)
methodList.Parent = methodFrame

local methodLayout = Instance.new("UIListLayout")
methodLayout.SortOrder = Enum.SortOrder.LayoutOrder
methodLayout.Padding = UDim.new(0, 6)
methodLayout.Parent = methodList

local function buildMethodStage()
    for _, c in ipairs(methodList:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local list = State.methods[State.selected.category] or {}
    for i, m in ipairs(list) do
        local card = Instance.new("TextButton")
        card.Size = UDim2.new(1, -6, 0, 52)
        card.BackgroundColor3 = Theme.panel
        card.BorderSizePixel = 0
        card.Text = ""
        card.LayoutOrder = i
        card.Parent = methodList
        corner(card, 10)
        stroke(card, Theme.stroke, 1)

        local nm = label(card, m.name, 12, Theme.text, Theme.fontBold)
        nm.Size = UDim2.new(1, -24, 0, 16)
        nm.Position = UDim2.new(0, 14, 0, 10)

        local ds = label(card, m.desc, 10, Theme.textDim, Theme.fontUI)
        ds.Size = UDim2.new(1, -24, 0, 14)
        ds.Position = UDim2.new(0, 14, 0, 28)
        ds.TextTruncate = Enum.TextTruncate.AtEnd

        card.MouseButton1Click:Connect(function()
            State.selected.method = m.id
            log("method: " .. m.name)
            showStage("addon")
        end)
    end
    methodList.CanvasSize = UDim2.new(0, 0, 0, methodLayout.AbsoluteContentSize.Y + 8)
end

makeBackBtn(methodFrame, function() showStage("category") end)

-- ============================================================
-- STAGE 3: ADDON
-- ============================================================
local addonFrame = makeStage("addon", "Хотите добавить аддон?", "step 3 / 3")

local addonHint = label(addonFrame, "Вставь исходник аддона или оставь пустым.", 10, Theme.textDim, Theme.fontMono)
addonHint.Size = UDim2.new(1, 0, 0, 16)
addonHint.Position = UDim2.new(0, 0, 0, 46)

local addonBox = Instance.new("TextBox")
addonBox.Size = UDim2.new(1, 0, 0, 110)
addonBox.Position = UDim2.new(0, 0, 0, 66)
addonBox.BackgroundColor3 = Theme.panel
addonBox.BorderSizePixel = 0
addonBox.Text = ""
addonBox.PlaceholderText = "-- addon source (optional)"
addonBox.TextColor3 = Theme.text
addonBox.PlaceholderColor3 = Theme.textDim
addonBox.TextSize = 11
addonBox.Font = Theme.fontMono
addonBox.TextXAlignment = Enum.TextXAlignment.Left
addonBox.TextYAlignment = Enum.TextYAlignment.Top
addonBox.ClearTextOnFocus = false
addonBox.MultiLine = true
addonBox.Parent = addonFrame
corner(addonBox, 10)
stroke(addonBox, Theme.stroke, 1)
pad(addonBox, 8)

local skipBtn = Instance.new("TextButton")
skipBtn.Size = UDim2.new(0, 100, 0, 30)
skipBtn.Position = UDim2.new(0, 0, 1, -30)
skipBtn.BackgroundColor3 = Theme.panelAlt
skipBtn.Text = "skip"
skipBtn.TextColor3 = Theme.textDim
skipBtn.TextSize = 11
skipBtn.Font = Theme.fontMono
skipBtn.BorderSizePixel = 0
skipBtn.Parent = addonFrame
corner(skipBtn, 6)
stroke(skipBtn, Theme.stroke, 1)

local confirmBtn = Instance.new("TextButton")
confirmBtn.Size = UDim2.new(0, 140, 0, 30)
confirmBtn.Position = UDim2.new(0, 106, 1, -30)
confirmBtn.BackgroundColor3 = Theme.accent
confirmBtn.Text = "confirm →"
confirmBtn.TextColor3 = Theme.bg
confirmBtn.TextSize = 11
confirmBtn.Font = Theme.fontBold
confirmBtn.BorderSizePixel = 0
confirmBtn.Parent = addonFrame
corner(confirmBtn, 6)

makeBackBtn(addonFrame, function() showStage("method") end).Position = UDim2.new(1, -80, 1, -30)

-- ============================================================
-- STAGE 4: INJECT
-- ============================================================
local injectFrame = makeStage("inject", "Внедрение обхода", "process")

local injectLog = Instance.new("ScrollingFrame")
injectLog.Size = UDim2.new(1, 0, 1, -50)
injectLog.Position = UDim2.new(0, 0, 0, 46)
injectLog.BackgroundColor3 = Theme.panel
injectLog.BorderSizePixel = 0
injectLog.ScrollBarThickness = 3
injectLog.ScrollBarImageColor3 = Theme.stroke
injectLog.CanvasSize = UDim2.new(0, 0, 0, 0)
injectLog.Parent = injectFrame
corner(injectLog, 10)
stroke(injectLog, Theme.stroke, 1)

local injectLogLabel = Instance.new("TextLabel")
injectLogLabel.BackgroundTransparency = 1
injectLogLabel.Size = UDim2.new(1, -16, 0, 0)
injectLogLabel.Position = UDim2.new(0, 8, 0, 8)
injectLogLabel.Text = ""
injectLogLabel.TextColor3 = Theme.textDim
injectLogLabel.TextSize = 11
injectLogLabel.Font = Theme.fontMono
injectLogLabel.TextXAlignment = Enum.TextXAlignment.Left
injectLogLabel.TextYAlignment = Enum.TextYAlignment.Top
injectLogLabel.AutomaticSize = Enum.AutomaticSize.Y
injectLogLabel.Parent = injectLog

local injectLines = {}
local function injectPrint(msg, color)
    table.insert(injectLines, string.format("[%s] %s", os.date("%H:%M:%S"), msg))
    injectLogLabel.Text = table.concat(injectLines, "\n")
    injectLog.CanvasSize = UDim2.new(0, 0, 0, injectLogLabel.AbsoluteSize.Y + 16)
    injectLog.CanvasPosition = Vector2.new(0, math.max(0, injectLogLabel.AbsoluteSize.Y - injectLog.AbsoluteSize.Y + 16))
end

local function runInjection()
    injectLines = {}
    injectPrint("инициализация внедрения...")
    task.wait(0.4)
    injectPrint("категория: " .. tostring(State.selected.category))
    task.wait(0.3)
    injectPrint("метод: " .. tostring(State.selected.method))
    task.wait(0.3)
    if State.selected.addon then
        injectPrint("аддон: загружен в песочницу")
        task.wait(0.3)
    else
        injectPrint("аддон: пропущен")
    end
    task.wait(0.2)
    injectPrint("поиск целей: LocalScript / RemoteEvent...")
    task.wait(0.6)
    injectPrint("установка хуков: __namecall, __index")
    task.wait(0.5)

    local Bypass = _G.BBAC_Bypass
    if Bypass then
        if Bypass.onToggle then pcall(Bypass.onToggle, State.selected.method, true) end
        if Bypass.activate then pcall(Bypass.activate) end
    else
        injectPrint("Bypass module not found — loading scaffold")
    end

    task.wait(0.4)
    injectPrint("синхронизация с сервером...")
    task.wait(0.5)
    injectPrint("внедрение завершено")
    task.wait(0.3)

    State.active = true
    statusDot.BackgroundColor3 = Theme.ok
    statusLbl.Text = "active"
    statusLbl.TextColor3 = Theme.ok

    showStage("success")
end

skipBtn.MouseButton1Click:Connect(function()
    State.selected.addon = nil
    showStage("inject")
    task.spawn(runInjection)
end)

confirmBtn.MouseButton1Click:Connect(function()
    local src = addonBox.Text
    if #src >= 3 then
        local fn, err = loadstring(src)
        if fn then
            local env = setmetatable({
                BBAC = {
                    register = function(name, cb)
                        table.insert(State.addons, { name = name, cb = cb })
                        log("addon registered: " .. tostring(name))
                    end,
                    log = log,
                },
                print = function(...) log(...) end,
            }, { __index = _G })
            local ok2, err2 = pcall(fn, env)
            if ok2 then
                State.selected.addon = src
                log("addon loaded")
            else
                log("addon runtime error: " .. tostring(err2))
                State.selected.addon = nil
            end
        else
            log("addon compile error: " .. tostring(err))
            State.selected.addon = nil
        end
    end
    showStage("inject")
    task.spawn(runInjection)
end)

-- ============================================================
-- STAGE 5: SUCCESS
-- ============================================================
local successFrame = makeStage("success", "Успешно", "обход внедрён в клиент")

local successBox = Instance.new("Frame")
successBox.Size = UDim2.new(1, 0, 0, 90)
successBox.Position = UDim2.new(0, 0, 0, 60)
successBox.BackgroundColor3 = Theme.panel
successBox.BorderSizePixel = 0
successBox.Parent = successFrame
corner(successBox, 10)
stroke(successBox, Theme.ok, 1)

local successIcon = label(successBox, "✓", 32, Theme.ok, Theme.fontBold, Enum.TextXAlignment.Center)
successIcon.Size = UDim2.new(1, 0, 0, 50)
successIcon.Position = UDim2.new(0, 0, 0, 6)

local successMsg = label(successBox, "античит обойдён, методы активны", 11, Theme.text, Theme.fontMono, Enum.TextXAlignment.Center)
successMsg.Size = UDim2.new(1, 0, 0, 18)
successMsg.Position = UDim2.new(0, 0, 0, 58)

local restartBtn = Instance.new("TextButton")
restartBtn.Size = UDim2.new(1, 0, 0, 32)
restartBtn.Position = UDim2.new(0, 0, 1, -32)
restartBtn.BackgroundColor3 = Theme.panelAlt
restartBtn.Text = "сбросить визард"
restartBtn.TextColor3 = Theme.text
restartBtn.TextSize = 11
restartBtn.Font = Theme.fontMono
restartBtn.BorderSizePixel = 0
restartBtn.Parent = successFrame
corner(restartBtn, 6)
stroke(restartBtn, Theme.stroke, 1)

restartBtn.MouseButton1Click:Connect(function()
    State.selected = { category = nil, method = nil, addon = nil }
    injectLines = {}
    injectLogLabel.Text = ""
    addonBox.Text = ""
    statusDot.BackgroundColor3 = Theme.textDim
    statusLbl.Text = "idle"
    statusLbl.TextColor3 = Theme.textDim
    showStage("category")
end)

-- ============================================================
-- INIT
-- ============================================================
showStage("category")
log("BBAC V0.1.0 wizard initialized")

_G.BBAC_Bypass = _G.BBAC_Bypass or {}
