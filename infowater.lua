local WatermarkNotify = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local Utility = {}

function Utility.Create(className, properties, children)
    local instance = Instance.new(className)
    if properties then
        for property, value in pairs(properties) do
            if property ~= "Parent" then
                instance[property] = value
            end
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = instance
        end
    end
    if properties and properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

function Utility.Tween(instance, properties, duration, easingStyle, easingDirection, callback)
    local tweenInfo = TweenInfo.new(
        duration or 0.3,
        easingStyle or Enum.EasingStyle.Quad,
        easingDirection or Enum.EasingDirection.Out,
        0,
        false,
        0
    )
    local tween = TweenService:Create(instance, tweenInfo, properties)
    if callback then
        tween.Completed:Connect(callback)
    end
    tween:Play()
    return tween
end

function Utility.MakeDraggable(frame, handle, callback)
    handle = handle or frame
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local dragConnection1, dragConnection2, dragConnection3
    local function updateInput(input)
        local delta = input.Position - dragStart
        local newPosition = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        frame.Position = newPosition
        if callback then
            callback(newPosition)
        end
    end
    dragConnection1 = handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            dragConnection2 = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    dragConnection3 = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                        input.UserInputType == Enum.UserInputType.Touch) then
            updateInput(input)
        end
    end)
    return {
        Disconnect = function()
            if dragConnection1 then dragConnection1:Disconnect() end
            if dragConnection2 then dragConnection2:Disconnect() end
            if dragConnection3 then dragConnection3:Disconnect() end
        end
    }
end

function Utility.GetTextBounds(text, font, size, maxWidth)
    return TextService:GetTextSize(text, size, font, Vector2.new(maxWidth or 1000, 1000))
end

function Utility.RandomString(length)
    length = length or 10
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = ""
    for i = 1, length do
        local randomIndex = math.random(1, #chars)
        result = result .. chars:sub(randomIndex, randomIndex)
    end
    return result
end

function Utility.LightenColor(color, amount)
    amount = amount or 0.2
    return Color3.new(
        math.min(1, color.R + amount),
        math.min(1, color.G + amount),
        math.min(1, color.B + amount)
    )
end

local Theme = {
    Background = Color3.fromRGB(25, 25, 25),
    Accent = Color3.fromRGB(88, 101, 242),
    Text = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(178, 178, 178),
    ElementBackground = Color3.fromRGB(35, 35, 35),
    Success = Color3.fromRGB(59, 165, 93),
    Error = Color3.fromRGB(237, 66, 69),
    Warning = Color3.fromRGB(250, 166, 26)
}

function WatermarkNotify:CreateWatermark(config)
    local cfg = {
        Text = config.Text or "Watermark",
        Position = config.Position or "TopLeft",
        CustomPosition = config.CustomPosition,
        Draggable = config.Draggable ~= false,
        FadeOnHold = config.FadeOnHold ~= false,
        HoldTime = config.HoldTime or 0.3,
        FadeSpeed = config.FadeSpeed or 0.3,
        Font = config.Font or Enum.Font.GothamSemibold,
        TextSize = config.TextSize or 14,
        TextColor = config.TextColor or Theme.Text,
        BackgroundColor = config.BackgroundColor or Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = config.BackgroundTransparency or 0.5,
        CornerRadius = config.CornerRadius or 6,
        Shadow = config.Shadow ~= false,
        Outline = config.Outline or false,
        OutlineColor = config.OutlineColor or Theme.Accent,
        Padding = config.Padding or 12,
        Icon = config.Icon,
        IconSize = config.IconSize or 16
    }

    local WatermarkObj = {}
    WatermarkObj.Holding = false
    WatermarkObj.HoldStart = 0
    WatermarkObj.Visible = true
    WatermarkObj.Connections = {}

    local ScreenGui = Utility.Create("ScreenGui", {
        Name = "Watermark_" .. Utility.RandomString(8),
        Parent = CoreGui,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 999999
    })
    WatermarkObj.ScreenGui = ScreenGui

    if cfg.Shadow then
        WatermarkObj.Shadow = Utility.Create("ImageLabel", {
            Name = "Shadow",
            Parent = ScreenGui,
            BackgroundTransparency = 1,
            Image = "rbxassetid://6015897843",
            ImageColor3 = Color3.fromRGB(0, 0, 0),
            ImageTransparency = 0.5,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(49, 49, 450, 450),
            Size = UDim2.new(0, 200, 0, 40),
            Position = UDim2.new(0, 0, 0, 0),
            Visible = false
        })
    end

    local MainFrame = Utility.Create("Frame", {
        Name = "Main",
        Parent = ScreenGui,
        BackgroundColor3 = cfg.BackgroundColor,
        BackgroundTransparency = cfg.BackgroundTransparency,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, 40),
        AutomaticSize = Enum.AutomaticSize.X
    })
    WatermarkObj.MainFrame = MainFrame

    local positions = {
        TopLeft = UDim2.new(0, 20, 0, 20),
        TopRight = UDim2.new(1, -20, 0, 20),
        TopCenter = UDim2.new(0.5, 0, 0, 20),
        BottomLeft = UDim2.new(0, 20, 1, -60),
        BottomRight = UDim2.new(1, -20, 1, -60),
        BottomCenter = UDim2.new(0.5, 0, 1, -60),
        Center = UDim2.new(0.5, 0, 0.5, 0)
    }

    if cfg.CustomPosition then
        MainFrame.Position = cfg.CustomPosition
    else
        MainFrame.Position = positions[cfg.Position] or positions.TopLeft
        if cfg.Position:find("Right") then
            MainFrame.AnchorPoint = Vector2.new(1, 0)
        elseif cfg.Position:find("Center") then
            MainFrame.AnchorPoint = Vector2.new(0.5, 0)
        end
    end

    if cfg.Outline then
        Utility.Create("UIStroke", {
            Color = cfg.OutlineColor,
            Thickness = 1,
            Parent = MainFrame
        })
    end

    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, cfg.CornerRadius),
        Parent = MainFrame
    })

    Utility.Create("UIListLayout", {
        Parent = MainFrame,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8)
    })

    Utility.Create("UIPadding", {
        Parent = MainFrame,
        PaddingLeft = UDim.new(0, cfg.Padding),
        PaddingRight = UDim.new(0, cfg.Padding),
        PaddingTop = UDim.new(0, cfg.Padding / 2),
        PaddingBottom = UDim.new(0, cfg.Padding / 2)
    })

    if cfg.Icon then
        local IconLabel = Utility.Create("ImageLabel", {
            Name = "Icon",
            Parent = MainFrame,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, cfg.IconSize, 0, cfg.IconSize),
            Image = cfg.Icon,
            ImageColor3 = cfg.TextColor
        })
        WatermarkObj.Icon = IconLabel
    end

    local TextLabel = Utility.Create("TextLabel", {
        Name = "Text",
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Font = cfg.Font,
        Text = cfg.Text,
        TextColor3 = cfg.TextColor,
        TextSize = cfg.TextSize,
        TextStrokeTransparency = 0.9,
        AutomaticSize = Enum.AutomaticSize.X
    })
    WatermarkObj.TextLabel = TextLabel

    local textBounds = Utility.GetTextBounds(cfg.Text, cfg.Font, cfg.TextSize)
    local totalWidth = textBounds.X + (cfg.Padding * 2)
    if cfg.Icon then
        totalWidth = totalWidth + cfg.IconSize + 8
    end
    MainFrame.Size = UDim2.new(0, totalWidth, 0, cfg.TextSize + cfg.Padding)

    if cfg.Shadow and WatermarkObj.Shadow then
        WatermarkObj.Shadow.Size = MainFrame.Size + UDim2.new(0, 30, 0, 30)
        WatermarkObj.Shadow.Position = MainFrame.Position - UDim2.new(0, 15, 0, 15)
        WatermarkObj.Shadow.AnchorPoint = MainFrame.AnchorPoint
        WatermarkObj.Shadow.Visible = true
    end

    if cfg.Draggable then
        local dragConnection = Utility.MakeDraggable(MainFrame, MainFrame, function(newPos)
            if cfg.Shadow and WatermarkObj.Shadow then
                WatermarkObj.Shadow.Position = newPos - UDim2.new(0, 15, 0, 15)
            end
        end)
        table.insert(WatermarkObj.Connections, dragConnection)
    end

    if cfg.FadeOnHold then
        local fadeConnection = nil
        local function startFade()
            WatermarkObj.Holding = true
            WatermarkObj.HoldStart = tick()
            fadeConnection = RunService.Heartbeat:Connect(function()
                if not WatermarkObj.Holding then
                    fadeConnection:Disconnect()
                    return
                end
                local holdTime = tick() - WatermarkObj.HoldStart
                if holdTime > cfg.HoldTime then
                    local progress = math.min((holdTime - cfg.HoldTime) / cfg.FadeSpeed, 1)
                    local alpha = progress * 0.9
                    MainFrame.BackgroundTransparency = cfg.BackgroundTransparency + (alpha * (1 - cfg.BackgroundTransparency))
                    TextLabel.TextTransparency = alpha
                    TextLabel.TextStrokeTransparency = 0.9 + (alpha * 0.1)
                    if WatermarkObj.Icon then
                        WatermarkObj.Icon.ImageTransparency = alpha
                    end
                    if WatermarkObj.Shadow then
                        WatermarkObj.Shadow.ImageTransparency = 0.5 + (alpha * 0.5)
                    end
                end
            end)
            table.insert(WatermarkObj.Connections, fadeConnection)
        end
        local function endFade()
            WatermarkObj.Holding = false
            if fadeConnection then
                fadeConnection:Disconnect()
            end
            Utility.Tween(MainFrame, {BackgroundTransparency = cfg.BackgroundTransparency}, 0.3)
            Utility.Tween(TextLabel, {TextTransparency = 0, TextStrokeTransparency = 0.9}, 0.3)
            if WatermarkObj.Icon then
                Utility.Tween(WatermarkObj.Icon, {ImageTransparency = 0}, 0.3)
            end
            if WatermarkObj.Shadow then
                Utility.Tween(WatermarkObj.Shadow, {ImageTransparency = 0.5}, 0.3)
            end
        end
        MainFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.Touch then
                startFade()
            end
        end)
        MainFrame.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.Touch then
                endFade()
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or 
                input.UserInputType == Enum.UserInputType.Touch) and WatermarkObj.Holding then
                endFade()
            end
        end)
    end

    function WatermarkObj:SetText(text)
        TextLabel.Text = text
        local bounds = Utility.GetTextBounds(text, cfg.Font, cfg.TextSize)
        local width = bounds.X + (cfg.Padding * 2)
        if cfg.Icon then
            width = width + cfg.IconSize + 8
        end
        MainFrame.Size = UDim2.new(0, width, 0, cfg.TextSize + cfg.Padding)
        if cfg.Shadow and WatermarkObj.Shadow then
            WatermarkObj.Shadow.Size = MainFrame.Size + UDim2.new(0, 30, 0, 30)
        end
    end

    function WatermarkObj:SetColor(color)
        TextLabel.TextColor3 = color
        if WatermarkObj.Icon then
            WatermarkObj.Icon.ImageColor3 = color
        end
    end

    function WatermarkObj:SetVisible(visible)
        WatermarkObj.Visible = visible
        ScreenGui.Enabled = visible
    end

    function WatermarkObj:Destroy()
        for _, conn in ipairs(WatermarkObj.Connections) do
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            elseif conn and conn.Disconnect then
                conn:Disconnect()
            end
        end
        ScreenGui:Destroy()
    end

    return WatermarkObj
end

function WatermarkNotify:CreateNotify(config)
    local cfg = {
        Title = config.Title or "Notification",
        Content = config.Content or "",
        Type = config.Type or "Info",
        Duration = config.Duration or 3,
        Icon = config.Icon,
        ShowProgress = config.ShowProgress ~= false,
        ProgressColor = config.ProgressColor,
        Buttons = config.Buttons or {},
        CloseButton = config.CloseButton ~= false
    }

    local typeColors = {
        Info = Theme.Accent,
        Success = Theme.Success,
        Warning = Theme.Warning,
        Error = Theme.Error
    }
    local accentColor = typeColors[cfg.Type] or typeColors.Info

    local ScreenGui = Utility.Create("ScreenGui", {
        Name = "Notify_" .. Utility.RandomString(8),
        Parent = CoreGui,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 999998
    })

    local MainFrame = Utility.Create("Frame", {
        Parent = ScreenGui,
        BackgroundColor3 = Theme.ElementBackground,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 320, 0, 0),
        Position = UDim2.new(1, -20, 1, -20),
        AnchorPoint = Vector2.new(1, 1),
        ClipsDescendants = true
    })

    local contentHeight = 70
    if cfg.Content and #cfg.Content > 0 then
        local textBounds = Utility.GetTextBounds(cfg.Content, Enum.Font.Gotham, 13, 280)
        contentHeight = 50 + textBounds.Y + 10
    end
    if #cfg.Buttons > 0 then
        contentHeight = contentHeight + 40
    end

    local Shadow = Utility.Create("ImageLabel", {
        Parent = ScreenGui,
        BackgroundTransparency = 1,
        Image = "rbxassetid://6015897843",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.6,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Size = UDim2.new(0, 350, 0, contentHeight + 30),
        Position = MainFrame.Position - UDim2.new(0, 15, 0, 15),
        AnchorPoint = Vector2.new(1, 1),
        ZIndex = 0
    })

    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = MainFrame
    })

    Utility.Create("Frame", {
        Parent = MainFrame,
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 4, 1, 0)
    })

    local iconIds = {
        Info = "rbxassetid://3944668821",
        Success = "rbxassetid://3944668821",
        Warning = "rbxassetid://3944668821",
        Error = "rbxassetid://3944668821"
    }

    Utility.Create("ImageLabel", {
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 15),
        Size = UDim2.new(0, 24, 0, 24),
        Image = cfg.Icon or iconIds[cfg.Type],
        ImageColor3 = accentColor
    })

    Utility.Create("TextLabel", {
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 52, 0, 12),
        Size = UDim2.new(1, -90, 0, 25),
        Font = Enum.Font.GothamBold,
        Text = cfg.Title,
        TextColor3 = Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    if cfg.CloseButton then
        local CloseBtn = Utility.Create("TextButton", {
            Parent = MainFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -35, 0, 10),
            Size = UDim2.new(0, 25, 0, 25),
            Font = Enum.Font.GothamBold,
            Text = "X",
            TextColor3 = Theme.TextDark,
            TextSize = 14
        })
        CloseBtn.MouseEnter:Connect(function()
            Utility.Tween(CloseBtn, {TextColor3 = Theme.Error}, 0.2)
        end)
        CloseBtn.MouseLeave:Connect(function()
            Utility.Tween(CloseBtn, {TextColor3 = Theme.TextDark}, 0.2)
        end)
        CloseBtn.MouseButton1Click:Connect(function()
            ScreenGui:Destroy()
        end)
    end

    Utility.Create("TextLabel", {
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 42),
        Size = UDim2.new(1, -40, 0, contentHeight - 60),
        Font = Enum.Font.Gotham,
        Text = cfg.Content,
        TextColor3 = Theme.TextDark,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    })

    if cfg.ShowProgress then
        local ProgressBar = Utility.Create("Frame", {
            Parent = MainFrame,
            BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -3),
            Size = UDim2.new(1, 0, 0, 3)
        })
        local ProgressFill = Utility.Create("Frame", {
            Parent = ProgressBar,
            BackgroundColor3 = cfg.ProgressColor or accentColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0)
        })
        Utility.Tween(ProgressFill, {Size = UDim2.new(0, 0, 1, 0)}, cfg.Duration, Enum.EasingStyle.Linear)
    end

    if #cfg.Buttons > 0 then
        local ButtonFrame = Utility.Create("Frame", {
            Parent = MainFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 20, 1, -45),
            Size = UDim2.new(1, -40, 0, 35)
        })
        Utility.Create("UIListLayout", {
            Parent = ButtonFrame,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 10)
        })
        for _, btnConfig in ipairs(cfg.Buttons) do
            local Button = Utility.Create("TextButton", {
                Parent = ButtonFrame,
                BackgroundColor3 = btnConfig.Primary and accentColor or Theme.Background,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 80, 1, 0),
                Font = Enum.Font.GothamSemibold,
                Text = btnConfig.Text or "Button",
                TextColor3 = btnConfig.Primary and Color3.fromRGB(255, 255, 255) or Theme.Text,
                TextSize = 12,
                AutoButtonColor = false
            })
            Utility.Create("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = Button
            })
            Button.MouseEnter:Connect(function()
                Utility.Tween(Button, {BackgroundColor3 = Utility.LightenColor(Button.BackgroundColor3, 0.1)}, 0.2)
            end)
            Button.MouseLeave:Connect(function()
                Utility.Tween(Button, {BackgroundColor3 = btnConfig.Primary and accentColor or Theme.Background}, 0.2)
            end)
            Button.MouseButton1Click:Connect(function()
                if btnConfig.Callback then
                    btnConfig.Callback()
                end
                if btnConfig.CloseOnClick ~= false then
                    ScreenGui:Destroy()
                end
            end)
        end
    end

    MainFrame.Size = UDim2.new(0, 320, 0, 0)
    MainFrame.Position = MainFrame.Position + UDim2.new(0, 50, 0, 0)
    Utility.Tween(MainFrame, {Size = UDim2.new(0, 320, 0, contentHeight)}, 0.4, Enum.EasingStyle.Back)
    Utility.Tween(MainFrame, {Position = MainFrame.Position - UDim2.new(0, 50, 0, 0)}, 0.4, Enum.EasingStyle.Back)

    task.delay(cfg.Duration, function()
        Utility.Tween(MainFrame, {Position = MainFrame.Position + UDim2.new(0, 50, 0, 0)}, 0.3)
        Utility.Tween(MainFrame, {Size = UDim2.new(0, 320, 0, 0)}, 0.3)
        Utility.Tween(Shadow, {ImageTransparency = 1}, 0.3)
        task.wait(0.3)
        ScreenGui:Destroy()
    end)

    return {
        Dismiss = function()
            ScreenGui:Destroy()
        end
    }
end

return WatermarkNotify