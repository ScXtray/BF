local Scripts = {
        {
                -- Sea 1: 2753915549 (lama), 85211729168715 (baru)
                -- Sea 2: 4442272183 (lama), 79091703265657 (baru)
                -- Sea 3: 7449423635 (lama), 100117331123089 (baru)
                PlacesIds = {
                        2753915549, 85211729168715,
                        4442272183, 79091703265657,
                        7449423635, 100117331123089
                },
                UrlPath = "BloxFruits.luau"
        },
}

local fetcher, urls = {}, {}

local _ENV = (getgenv or getrenv or getfenv)()

urls.Owner      = "https://raw.githubusercontent.com/ScXtray/";
urls.Repository = urls.Owner .. "BF/refs/heads/main/";
urls.Translator = urls.Repository .. "Translator/";
urls.Utils      = urls.Repository .. "Utils/";

do
        local last_exec = _ENV.rz_execute_debounce

        if last_exec and (tick() - last_exec) <= 5 then
                return nil
        end

        _ENV.rz_execute_debounce = tick()
end

do
        local executor     = syn or fluxus
        local queueteleport = queue_on_teleport or (executor and executor.queue_on_teleport)

        if not _ENV.rz_added_teleport_queue and type(queueteleport) == "function" then
                local ScriptSettings = {...}
                local SettingsCode   = ""

                _ENV.rz_added_teleport_queue = true

                local Success, EncodedSettings = pcall(function()
                        return game:GetService("HttpService"):JSONEncode(ScriptSettings)
                end)

                if Success and EncodedSettings then
                        SettingsCode = "unpack(game:GetService('HttpService'):JSONDecode('" .. EncodedSettings .. "'))"
                end

                pcall(queueteleport, ("loadstring(game:HttpGet('%smain.luau'))(%s)"):format(urls.Repository, SettingsCode))
        end
end

do
        if _ENV.rz_error_message then
                _ENV.rz_error_message:Destroy()
        end

        local identifyexecutor = identifyexecutor or (function() return "Unknown" end)

        local function CreateMessageError(Text)
                _ENV.loadedFarm  = nil
                _ENV.OnFarm      = false

                local Message    = Instance.new("Message", workspace)
                Message.Text     = string.gsub(Text, urls.Owner, "")
                _ENV.rz_error_message = Message

                error(Text, 2)
        end

        local function formatUrl(Url)
                for key, path in urls do
                        if Url:find("{" .. key .. "}") then
                                return Url:gsub("{" .. key .. "}", path)
                        end
                end
                return Url
        end

        function fetcher.get(Url)
                local success, response = pcall(function()
                        return game:HttpGet(formatUrl(Url))
                end)

                if success then
                        return response
                else
                        CreateMessageError(`[1] [{ identifyexecutor() }] failed to get http/url/raw: { Url }\n>>{ response }<<`)
                end
        end

        function fetcher.load(Url: string, concat: string?)
                local raw = fetcher.get(Url) .. (if concat then concat else "")
                local runFunction, errorText = loadstring(raw)

                if type(runFunction) ~= "function" then
                        CreateMessageError(`[2] [{ identifyexecutor() }] sintax error: { Url }\n>>{ errorText }<<`)
                else
                        return runFunction
                end
        end
end

local function IsPlace(Script)
        if Script.PlacesIds and table.find(Script.PlacesIds, game.PlaceId) then
                return true
        elseif Script.GameId and Script.GameId == game.GameId then
                return true
        end
end

local GameFound = false

for _, Script in Scripts do
        if IsPlace(Script) then
                GameFound = true
                return fetcher.load("{Repository}Games/" .. Script.UrlPath)(fetcher, ...)
        end
end

if not GameFound then
        local Message = Instance.new("Message", workspace)
        Message.Text  = ("[Xtray Script] Game tidak didukung! PlaceId: %d | Saat ini hanya mendukung Blox Fruits (Sea 1/2/3)."):format(game.PlaceId)
        task.delay(8, function()
                if Message and Message.Parent then
                        Message:Destroy()
                end
        end)
end
