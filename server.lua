ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Clés API
local OPENAI_API_KEY = "votre_cle_api_openai" -- Remplacez par votre clé OpenAI
local TTS_API_KEY = "votre_cle_api_tts" -- Remplacez par votre clé API TTS
local CHATGPT_URL = "https://api.openai.com/v1/chat/completions"
local TTS_URL = "https://texttospeech.googleapis.com/v1/text:synthesize"

-- Fonction pour obtenir une réponse de ChatGPT
function GetChatGPTResponse(prompt, cb)
    PerformHttpRequest(CHATGPT_URL, function(errorCode, resultData, resultHeaders)
        if errorCode == 200 then
            local result = json.decode(resultData)
            local response = result.choices[1].message.content
            cb(response)
        else
            print("Erreur avec l'API ChatGPT : " .. errorCode)
            cb(nil)
        end
    end, 'POST', json.encode({
        model = "gpt-3.5-turbo",
        messages = {
            { role = "system", content = "Vous êtes un PNJ dans un jeu vidéo." },
            { role = "user", content = prompt }
        }
    }), {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. OPENAI_API_KEY
    })
end

-- Fonction pour générer un fichier audio via TTS
function GenerateTTSAudio(text, cb)
    PerformHttpRequest(TTS_URL, function(errorCode, resultData, resultHeaders)
        if errorCode == 200 then
            local result = json.decode(resultData)
            local audioContent = result.audioContent -- Contenu audio encodé en base64
            cb(audioContent)
        else
            print("Erreur avec l'API TTS : " .. errorCode)
            cb(nil)
        end
    end, 'POST', json.encode({
        input = { text = text },
        voice = { languageCode = "en-US", name = "en-US-Wavenet-D" },
        audioConfig = { audioEncoding = "MP3" }
    }), {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. TTS_API_KEY
    })
end

-- Événement pour gérer les missions avec PNJ et IA
RegisterNetEvent('mission_ai:requestDialogue')
AddEventHandler('mission_ai:requestDialogue', function(prompt)
    local _source = source

    GetChatGPTResponse(prompt, function(chatResponse)
        if chatResponse then
            GenerateTTSAudio(chatResponse, function(audioContent)
                if audioContent then
                    TriggerClientEvent('mission_ai:receiveDialogue', _source, chatResponse, audioContent)
                else
                    TriggerClientEvent('mission_ai:receiveDialogue', _source, chatResponse, nil)
                end
            end)
        else
            TriggerClientEvent('mission_ai:receiveDialogue', _source, "Je suis désolé, je ne peux pas répondre pour le moment.", nil)
        end
    end)
end)
