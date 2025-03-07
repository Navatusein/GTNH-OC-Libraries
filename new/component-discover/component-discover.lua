local component = require("component")

---Escape special chars from pattern
---@param text string
---@return string
local function escapePattern(text)
  local specialChars = "().%+-*?[^$"
  local escapePattern = text:gsub("([%" .. specialChars .. "])", "%%%1")
  return escapePattern
end

---Get sides for check without ignored sides
---@param ignoreSides integer[]
---@return integer[]
local function getSidesForCheck(ignoreSides)
  local sidesForCheck = {0, 1, 2, 3, 4, 5}

  for _, ignoreSide in pairs(ignoreSides) do
    for sideIndex, side in pairs(sidesForCheck) do
      if ignoreSide == side then
        table.remove(sidesForCheck, sideIndex)
      end
    end
  end

  return sidesForCheck
end

local componentDiscover = {}

---Discover component proxy by type
---@generic T
---@param type `T`
---@param name string
---@return T
function componentDiscover.discoverComponent(type, name)
  local success, result = xpcall(component.getPrimary, debug.traceback, type)

  if success == false then
    error("Cant find "..type.." "..name)
  end

  return result
end

---Discover component proxy by address part
---@generic T
---@param address string
---@param type `T`
---@param name string
---@return T
function componentDiscover.discoverProxy(address, type, name)
  local fullAddress = component.get(address, type)

  if fullAddress == nil then
    error("Invalid address of "..type.." "..name)
  end

  return component.proxy(fullAddress, type)
end

---Discover gt_machine by name
---@param machineName string
---@return gt_machine|nil
function componentDiscover.discoverGtMachine(machineName)
  for key, value in pairs(component.list()) do
    if value == "gt_machine" then
      local machineProxy = component.proxy(key, "gt_machine")
      if string.match(machineProxy.getName(), machineName) ~= nil then
        return machineProxy
      end
    end
  end

  return nil
end

---Discover gt_machines by name
---@param machineName string
---@return gt_machine[]
function componentDiscover.discoverGtMachines(machineName)
  local result = {}

  for key, value in pairs(component.list()) do
    if value == "gt_machine" then
      local machineProxy = component.proxy(key, "gt_machine")

      if string.match(machineProxy.getName(), machineName) ~= nil then
        table.insert(result, machineProxy)
      end
    end
  end

  return result
end

---Discover item storages sides connected to transposer
---@param proxy transposer
---@param ignoreSides? integer[]
---@return table
function componentDiscover.discoverTransposerItemStorageSide(proxy, ignoreSides)
  ignoreSides = ignoreSides or {}

  local sides = {}
  local sidesForCheck = getSidesForCheck(ignoreSides)

  for _, side in pairs(sidesForCheck) do
    local stacks = proxy.getAllStacks(side)

    if stacks ~= nil then
      table.insert(sides, side)
    end
  end

  return sides
end

---Discover item storage connected to transposer
---@param proxy transposer
---@param itemLabels string[]
---@param ignoreSides? integer[]
---@return TransposerItemStorageDescriptor[]
---@return string[]
function componentDiscover.discoverTransposerItemStorage(proxy, itemLabels, ignoreSides)
  ignoreSides = ignoreSides or {}

  local itemStorageDescriptor = {}
  local sidesForCheck = getSidesForCheck(ignoreSides)

  for _, side in pairs(sidesForCheck) do
    local stacks = proxy.getAllStacks(side)

    if stacks ~= nil then
      local slots = stacks.getAll()

      for slotIndex, slot in pairs(slots) do
        if next(slot) ~= nil then
          for itemLabelIndex, itemLabel in pairs(itemLabels) do
            if slot.label ~= nil and string.match(slot.label, escapePattern(itemLabel)) then
              table.remove(itemLabels, itemLabelIndex)
              itemStorageDescriptor[itemLabel] = {side = side, slot = slotIndex + 1}
              break
            end
          end
        end
      end
    end
  end

  return itemStorageDescriptor, itemLabels
end

---Discover fluid storage connected to transposer
---@param proxy transposer
---@param fluidNames string[]
---@param ignoreSides? integer[]
---@return TransposerFluidStorageDescriptor[]
---@return string[]
function componentDiscover.discoverTransposerFluidStorage(proxy, fluidNames, ignoreSides)
  ignoreSides = ignoreSides or {}
  local fluidStorageDescriptor = {}
  local sidesForCheck = getSidesForCheck(ignoreSides)

  for _, side in pairs(sidesForCheck) do
    if proxy.getTankCount(side) ~= 0 then
      local tankCount = proxy.getTankCount(side)

      for tankIndex = 1, tankCount, 1 do
        local fluid = proxy.getFluidInTank(side, tankIndex)

        for fluidNameIndex, fluidName in pairs(fluidNames) do
          if fluid.name ~= nil and string.match(fluid.name, escapePattern(fluidName)) then
            table.remove(fluidNames, fluidNameIndex)
            fluidStorageDescriptor[fluidName] = {side = side, tank = tankIndex}
            break
          end
        end
      end
     end
  end

  return fluidStorageDescriptor, fluidNames
end

return componentDiscover