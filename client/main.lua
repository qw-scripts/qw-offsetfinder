local shellHandle = nil
local objectHandle = nil
local oldCoords = nil
local testingShell = false
local inObjectPreview = false
local placedPreviews = {}

local function Notify(msg)
    lib.notify({
        title = 'Offset Finder',
        description = msg,
        type = 'success'
    })
end

local function removePlaceholderObjects()
    for i = 1, #placedPreviews do
        local preview = placedPreviews[i]
        
        if DoesEntityExist(preview) then
            DeleteEntity(preview)
        end
    end

    placedPreviews = {}
end

local function RemoveShell()
    if not shellHandle then
        return
    end

    testingShell = false
    lib.hideTextUI()
    DeleteEntity(shellHandle)
    shellHandle = nil

    if objectHandle and DoesEntityExist(objectHandle) then
        inObjectPreview = false
        DeleteEntity(objectHandle)
        objectHandle = nil
    end

    removePlaceholderObjects()

    SetEntityCoordsNoOffset(cache.ped, oldCoords)
    oldCoords = nil

    Notify("Deleted shell")
end

RegisterNetEvent("qw-offset:client:testShell", function(shellName)
    local shellModel = shellName and GetHashKey(shellName)

    if not shellName then
        return Notify(("No such shell \"%s\"."):format(shellName or ""))
    elseif not IsModelInCdimage(shellModel) then
        return Notify(("The shell \"%s\" is not in cd image, did you start the shell?"):format(shellName))
    end

    if DoesEntityExist(shellHandle) then
        DeleteEntity(shellHandle)
        shellHandle = nil
    else
        oldCoords = GetEntityCoords(cache.ped)
    end

    local input = lib.inputDialog('Shell Z Coord', {
        {
            type = 'number',
            label = 'Z Coord Offset',
            description = 'How High or Low to Spawn the Shell',
            icon = 'hashtag',
            required = true,
            default = 0.0
        },
    })

    if not input then
        return
    end

    shellHandle = CreateObject(shellModel, oldCoords + vec3(0.0, 0.0, input[1]), true, true)
    FreezeEntityPosition(shellHandle, true)
    SetEntityHeading(shellHandle, 0.0)

    SetEntityCoordsNoOffset(cache.ped, GetEntityCoords(shellHandle))

    testingShell = true

    lib.showTextUI('[E] - Copy Offset  \n [Q] - Remove Shell', {
        position = "left-center",
    })

    CreateThread(function()
        while testingShell do
            Wait(0)

            if IsControlJustPressed(0, 44) then RemoveShell() end

            if IsControlJustPressed(0, 38) then
                if not shellHandle then
                    return
                end

                local coords = GetEntityCoords(PlayerPedId())

                local coordsToCompare = inObjectPreview and GetEntityCoords(objectHandle) or coords

                local offset = GetOffsetFromEntityGivenWorldCoords(shellHandle, coordsToCompare)

                lib.setClipboard(('vec4(%f, %f, %f, %f)'):format(offset.x, offset.y, offset.z,
                    GetEntityHeading(inObjectPreview and objectHandle or cache.ped)))
                Notify("Copied offset to clipboard.")
            end
        end
    end)
end)

RegisterNetEvent('qw-offset:client:objectOffsetMode', function()

    if not testingShell then return end
    if not inObjectPreview then

        local input = lib.inputDialog('Object Model Preview', {
            {
                type = 'input',
                label = 'Object Name',
                required = true,
            },
        })
    
        if not input then
            return
        end

        local object = tostring(input[1])

        local objectModel = object and GetHashKey(object)

        if not IsModelInCdimage(objectModel) then
            return Notify(("The object \"%s\" is not in cd image, are you sure this exists?"):format(objectModel))
        end

        inObjectPreview = true

        lib.requestModel(objectModel, 1000)

        objectHandle = CreateObject(objectModel, GetEntityCoords(cache.ped), true, true, false)

        SetEntityAlpha(objectHandle, 150, false)
        SetEntityCollision(objectHandle, false, false)
        FreezeEntityPosition(objectHandle, true)

        lib.hideTextUI()
        lib.showTextUI('[E] - Copy Offset  \n [Q] - Remove Shell  \n [L/R Arrow] Rotate Object', {
            position = "left-center",
        })

        CreateThread(function()
            while inObjectPreview do
                local hit, _, coords, _, _ = lib.raycast.cam(1, 4)
                if hit then
                    SetEntityCoords(objectHandle, coords.x, coords.y, coords.z)
                    PlaceObjectOnGroundProperly(objectHandle)

                    if IsControlPressed(0, 174) then
                        SetEntityHeading(objectHandle, GetEntityHeading(objectHandle) - 1.0)
                    end

                    if IsControlPressed(0, 175) then
                        SetEntityHeading(objectHandle, GetEntityHeading(objectHandle) + 1.0)
                    end

                    if IsControlJustPressed(0, 38) then
                        local placeholderObject = CreateObject(objectModel, coords.x, coords.y, coords.z, true, true, false)
                        SetEntityHeading(placeholderObject, GetEntityHeading(objectHandle))
                        
                        PlaceObjectOnGroundProperly(placeholderObject)
                        SetEntityAlpha(placeholderObject, 150, false)
                        SetEntityCollision(placeholderObject, false, false)
                        FreezeEntityPosition(placeholderObject, true)
                        SetEntityDrawOutline(placeholderObject, true)
                        SetEntityDrawOutlineColor(0, 255, 0, 150)


                        placedPreviews[#placedPreviews+1] = placeholderObject
                    end
                end

                Wait(0)
            end
        end)
    else
        if objectHandle and DoesEntityExist(objectHandle) then
            inObjectPreview = false
            DeleteEntity(objectHandle)
            objectHandle = nil
        end

        lib.hideTextUI()
        lib.showTextUI('[E] - Copy Offset  \n [Q] - Remove Shell', {
            position = "left-center",
        })
    end
end)
