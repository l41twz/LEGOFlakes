VERSION = "1.0.0"

local micro = import("micro")
local config = import("micro/config")
local buffer = import("micro/buffer")
local shell = import("micro/shell")

function init()
    config.MakeCommand("gemini", geminiCommand, config.NoComplete)
    
    -- Tenta bind Ctrl-1
    local success, err = pcall(function() 
        config.TryBindKey("Ctrl-1", "lua:gemini.geminiCommand", false) 
    end)
    if not success then
        micro.Log("Gemini Plugin: Erro ao bindar Ctrl-1: " .. tostring(err))
    end

    -- Adiciona Alt-h como alternativa
    config.TryBindKey("Alt-h", "lua:gemini.geminiCommand", false)
end

-- Make function global
_G.geminiCommand = geminiCommand

function geminiCommand(bp)
    local buf = bp.Buf
    local cursor = buf:GetActiveCursor()
    
    -- Check if there's a selection
    if cursor:HasSelection() then
        local selection = cursor:GetSelection()
        
        -- Ask user: (p)rompt or (m)elhorar?
        micro.InfoBar():Prompt("(p)rompt ou (m)elhorar? ", "", "GeminiMode", nil, function(resp)
            if resp == "p" or resp == "P" then
                -- Use selection as prompt, insert after
                queryGemini(selection, function(result)
                    cursor:Deselect(true)
                    cursor:GotoLoc(buffer.Loc(cursor.Loc.X, cursor.Loc.Y))
                    buf:Insert(buffer.Loc(cursor.Loc.X, cursor.Loc.Y), "\n" .. result)
                    cursor:Relocate()
                end)
            elseif resp == "m" or resp == "M" then
                -- Send selection to improve, replace it
                local improvePrompt = "Melhore o seguinte código/texto:\n\n" .. selection
                queryGemini(improvePrompt, function(result)
                    local start = cursor.CurSelection[1]
                    local finish = cursor.CurSelection[2]
                    buf:Replace(start, finish, result)
                    cursor:Deselect(true)
                    cursor:Relocate()
                end)
            else
                micro.InfoBar():Message("Cancelado")
            end
        end)
    else
        -- No selection: prompt user for input
        micro.InfoBar():Prompt("Pergunta para Gemini: ", "", "GeminiPrompt", nil, function(prompt)
            if prompt ~= "" then
                queryGemini(prompt, function(result)
                    buf:Insert(buffer.Loc(cursor.Loc.X, cursor.Loc.Y), result)
                    cursor:Relocate()
                end)
            end
        end)
    end
end

function queryGemini(prompt, callback)
    local scriptPath = os.getenv("HOME") .. "/LEGOFlakes/config/micro/gemini-query.nu"
    
    -- Executa via sh -c para garantir que 'nu' seja encontrado no PATH e argumentos com espaços funcionem
    local shellCmd = "nu '" .. scriptPath .. "' '" .. prompt:gsub("'", "'\\''") .. "'"
    local args = {"-c", shellCmd}
    
    micro.Log("Gemini Plugin: Executing via sh: " .. shellCmd)
    
    shell.JobSpawn("sh", args, function(output)
        callback(output)
    end, function(errOutput)
        -- stderr callback
        if errOutput and errOutput ~= "" then
            micro.Log("Gemini Plugin Stderr: " .. errOutput)
        end
    end, function(exitStr)
        -- onExit callback
        micro.Log("Gemini Plugin Exit: " .. tostring(exitStr))
    end)
end
