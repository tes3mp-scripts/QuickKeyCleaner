local QuickKeyCleaner = {}

-- Setup
QuickKeyCleaner.scriptName = 'QuickKeyCleaner'
QuickKeyCleaner.defaultConfig = {
    keyOrder = { "removeRefIds", "restrictedCells", "hotkeyPlaceholder" },
    values = {
        removeRefIds = {},
        restrictedCells = {},
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

QuickKeyCleaner.restrictedCells = {}
for i, v in pairs(QuickKeyCleaner.config.restrictedCells) do
    QuickKeyCleaner.restrictedCells[v] = true
end

QuickKeyCleaner.hotkeyPlaceholder = QuickKeyCleaner.config.hotkeyPlaceholder
QuickKeyCleaner.hotkeyPlaceholder.count = 1

QuickKeyCleaner.filters = {}

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

function QuickKeyCleaner.isCellRestricted(cellName)
    return QuickKeyCleaner.restrictedCells[cellName] == true
end

function QuickKeyCleaner.registerFilter(func)
    table.insert(QuickKeyCleaner, func)
end

function QuickKeyCleaner.isBanned(refId)
    if QuickKeyCleaner.removeRefIds[refId] == true then
        return true
    end
    for _, f in pairs(QuickKeyCleaner.filters) do
        if not f(refId) then
            return true
        end
    end
    return false
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
QuickKeyCleaner.allSlots = { 1, 2, 3, 4, 5, 6, 7, 8, 9}
customEventHooks.registerHandler("OnPlayerCellChange", function(eventStatus, pid)
    local currentCell = tes3mp.GetCell(pid)
    local cellCheck = QuickKeyCleaner.isCellRestricted(currentCell)
    if cellCheck then
        local allSlots = QuickKeyCleaner.allSlots
        QuickKeyCleaner.clearSlots(pid, allSlots)
    end
end)

customEventHooks.registerValidator("OnPlayerQuickKeys", function(eventStatus, pid)
    local slots = {}
    local currentCell = tes3mp.GetCell(pid)
    local cellCheck = QuickKeyCleaner.isCellRestricted(currentCell)
    if cellCheck then
        local allSlots = QuickKeyCleaner.allSlots
        QuickKeyCleaner.clearSlots(pid, allSlots)
        return customEventHooks.makeEventStatus(false, false)
    else
        for index = 0, tes3mp.GetQuickKeyChangesSize(pid) - 1 do
            tes3mp.LogMessage(2, tes3mp.GetQuickKeyItemId(pid, index))
            if QuickKeyCleaner.isBanned(tes3mp.GetQuickKeyItemId(pid, index)) then
                local slot = tes3mp.GetQuickKeySlot(pid, index)
                table.insert(slots, slot)
            end
        end
        if #slots > 0 then
            QuickKeyCleaner.clearSlots(pid, slots)
            return customEventHooks.makeEventStatus(false, false)
        end
    end
end)

customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
    local currentCell = tes3mp.GetCell(pid)
    local cellCheck = QuickKeyCleaner.isCellRestricted(currentCell)
    if cellCheck then
        QuickKeyCleaner.clearSlots(pid, QuickKeyCleaner.allSlots)
    else
        QuickKeyCleaner.filterQuickKeys(pid)
    end
end)

customEventHooks.registerHandler("OnServerPostInit", function(eventStatus, pid)
    QuickKeyCleaner.createHotkeyPlaceholder()
end)


return QuickKeyCleaner