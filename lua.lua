local WebhookURL = "https://discord.com/api/webhooks/1490366265246744827/VXabTPDqWEFrBBmZqEBjI3xfuzgKzNgJJrUSc-RicrmS6XzaWFhrWWKQDEsqLPt95KYk"
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

local loadedScripts = {}

local function SendWebhook(ScriptName)
    local Data = {
        embeds = {{
            title = "Xi Pro 脚本加载",
            color = 16711680,
            fields = {
                {name = "玩家名称", value = LP.Name, inline = true},
                {name = "用户ID", value = tostring(LP.UserId), inline = true},
                {name = "使用时间", value = os.date("%Y-%m-%d %H:%M:%S"), inline = true},
                {name = "服务器ID", value = game.JobId, inline = true},
                {name = "游戏名称", value = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name, inline = true},
                {name = "加载的脚本", value = ScriptName, inline = false}
            },
            footer = {text = "Xi Pro | 联邦版"},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
        }}
    }
    pcall(function()
        request({
            Url = WebhookURL, 
            Method = "POST", 
            Headers = {["Content-Type"] = "application/json"}, 
            Body = HttpService:JSONEncode(Data)
        })
    end)
end

local originalLoad = Load
Load = function(n, c)
    originalLoad(n, c)
    if not loadedScripts[n] then
        loadedScripts[n] = true
        task.spawn(function()
            SendWebhook(n)
        end)
    end
end