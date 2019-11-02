local QuickKeyCleaner = {}

-- Setup
QuickKeyCleaner.scriptName = 'QuickKeyCleaner'
QuickKeyCleaner.defaultConfig = {
    keyOrder = { "removeRefIds", },
    values = {
        removeRefIds = {},
        hotkeyPlaceholder = {
            type = "miscellaneous",
            refId = "hotkey_placeholder",
            name = "Empty",
		    icon = "m\\misc_dwrv_Ark_cube00.tga"
        }
    }
}
QuickKeyCleaner.config = DataManager.loadConfiguration(
    QuickKeyCleaner.scriptName,
    QuickKeyCleaner.defaultConfig.values,
    QuickKeyCleaner.defaultConfig.keyOrder
)

QuickKeyCleaner.removeRefIds = {}
for i, v in pairs(QuickKeyCleaner.config.removeRefIds) do
    QuickKeyCleaner.removeRefIds[v] = true
end

QuickKeyCleaner.hotkeyPlaceholder = QuickKeyCleaner.config.hotkeyPlaceholder
QuickKeyCleaner.hotkeyPlaceholder.count = 1

-- Methods
function QuickKeyCleaner.createHotkeyPlaceholder()
    local recordStore = RecordStores[QuickKeyCleaner.config.hotkeyPlaceholder.type]
    if recordStore.data.permanentRecords[QuickKeyCleaner.config.hotkeyPlaceholder.refId] == nil then
        recordStore.data.permanentRecords[QuickKeyCleaner.config.hotkeyPlaceholder.refId] = QuickKeyCleaner.hotkeyPlaceholder
        recordStore:Save()
    end
end

function QuickKeyCleaner.getEmptyHotkey()
    return {
        keyType = 0,
        itemId = QuickKeyCleaner.config.hotkeyPlaceholder.refId
    }
end

function QuickKeyCleaner.isBanned(refId)
    return QuickKeyCleaner.removeRefIds[refId] == true
end

function QuickKeyCleaner.banItem(refId)
    QuickKeyCleaner.removeRefIds[refId] = true
end

function QuickKeyCleaner.unbanItem(refId)
    QuickKeyCleaner.removeRefIds[refId] = nil
end

function QuickKeyCleaner.addHotkeyPlaceholder(pid)
    tes3mp.ClearInventoryChanges(pid)
    tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.ADD)
    packetBuilder.AddPlayerInventoryItemChange(pid, QuickKeyCleaner.hotkeyPlaceholder)
    tes3mp.SendInventoryChanges(pid)
end

function QuickKeyCleaner.removeHotkeyPlaceholder(pid)
    tes3mp.ClearInventoryChanges(pid)
    tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.REMOVE)
    packetBuilder.AddPlayerInventoryItemChange(pid, QuickKeyCleaner.hotkeyPlaceholder)
    tes3mp.SendInventoryChanges(pid)
end

function QuickKeyCleaner.clearSlots(pid, slots)
    if #slots == 0 then
        return
    end
    local quickKeys = Players[pid].data.quickKeys
    tes3mp.ClearQuickKeyChanges(pid)
    for i = 1, #slots do
        local k = slots[i]
        quickKeys[k] = QuickKeyCleaner.getEmptyHotkey()
        tes3mp.AddQuickKey(pid, k, quickKeys[k].keyType, quickKeys[k].itemId)
    end
    QuickKeyCleaner.addHotkeyPlaceholder(pid)
    tes3mp.SendQuickKeyChanges(pid)
    QuickKeyCleaner.removeHotkeyPlaceholder(pid)
end

function QuickKeyCleaner.filterQuickKeys(pid)
    local quickKeys = Players[pid].data.quickKeys
    local slots = {}

    for k = 1, 9 do
        if quickKeys[k] ~= nil and QuickKeyCleaner.isBanned(quickKeys[k].itemId) then
            table.insert(slots, k)
        end
    end

    QuickKeyCleaner.clearSlots(pid, slots)
end

-- Hooks
customEventHooks.registerValidator("OnPlayerQuickKeys", function(eventStatus, pid)
    local slots = {}
    tes3mp.LogMessage(2, "QUICK KEYS")
    for index = 0, tes3mp.GetQuickKeyChangesSize(pid) - 1 do
        tes3mp.LogMessage(2, tes3mp.GetQuickKeyItemId(pid, index))
        if QuickKeyCleaner.isBanned(tes3mp.GetQuickKeyItemId(pid, index)) then
            tes3mp.LogMessage(2, "BANNED")
            local slot = tes3mp.GetQuickKeySlot(pid, index)
            table.insert(slots, slot)
        end
    end

    if #slots > 0 then
        tes3mp.LogMessage(2, "CLEARING SLOTS")
        QuickKeyCleaner.clearSlots(pid, slots)
        return customEventHooks.makeEventStatus(false, false)
    end
end)

customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
    QuickKeyCleaner.filterQuickKeys(pid)
end)

customEventHooks.registerHandler("OnServerPostInit", function(eventStatus, pid)
    QuickKeyCleaner.createHotkeyPlaceholder()
end)


return QuickKeyCleaner