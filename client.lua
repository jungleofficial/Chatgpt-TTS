local missionNPCs = {}

-- Fonction pour créer un PNJ interactif
function CreateMissionNPC(modelHash, x, y, z, heading)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(1) end

    local ped = CreatePed(4, modelHash, x, y, z, heading, false, true)
    SetEntityAsMissionEntity(ped, true, true)

    return ped
end

-- Fonction pour afficher un dialogue à l'écran (texte uniquement ou voix + texte)
function DisplayDialogue(text)
    AddTextEntry('NPC_DIALOGUE', text)
    BeginTextCommandDisplayHelp('NPC_DIALOGUE')
    EndTextCommandDisplayHelp(0, false, true, 5000)
end

-- Fonction pour jouer un fichier audio encodé en base64 (TTS Audio)
function PlayAudioFromBase64(audioContentBase64)
    local decodedFilePath = GetResourcePath(GetCurrentResourceName()) .. "/tts_audio.mp3"
    
    SaveResourceFile(GetCurrentResourceName(), "tts_audio.mp3", audioContentBase64)

    -- Exemple de lecture audio avec xsound (à installer séparément si nécessaire).
    TriggerEvent("xsound:play", decodedFilePath) 
end

-- Gestion des interactions joueur-PNJ avec ChatGPT et TTS
function HandlePlayerInteraction(pedID)
    Citizen.CreateThread(function()
        while true do
            Wait(500)

            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            for _, npc in pairs(missionNPCs) do
                local npcCoords = GetEntityCoords(npc.ped)

                if #(playerCoords - npcCoords) < 3.0 and not npc.interacted then -- Si le joueur est proche d'un PNJ non encore interacté.
                    TaskLookAtEntity(npc.ped, playerPed, -1)

                    -- Demande au serveur une réponse de ChatGPT et un fichier audio TTS.
                    TriggerServerEvent('mission_ai:requestDialogue', npc.prompt)

                    npc.interacted = true -- Marquer comme déjà interacté.
                end
            end
        end
    end)
end

-- Événement pour recevoir le dialogue depuis le serveur (ChatGPT + TTS).
RegisterNetEvent('mission_ai:receiveDialogue')
AddEventHandler('mission_ai:receiveDialogue', function(responseText, audioContentBase64)
    DisplayDialogue(responseText) -- Afficher le texte.

    if audioContentBase64 then PlayAudioFromBase64(audioContentBase64) end -- Lire l'audio si disponible.
end)

-- Création des PNJ de mission au démarrage du client.
Citizen.CreateThread(function()
    table.insert(missionNPCs, {
        ped = CreateMissionNPC(GetHashKey("a_m_m_farmer_01"), -1037.5, -2737.5, 20.2, 90.0),
        prompt = "Bonjour ! Que puis-je faire pour vous aujourd'hui ?",
        interacted = false -- Statut d'interaction.
    })

    HandlePlayerInteraction() -- Gérer les interactions joueur-PNJ.
end)
