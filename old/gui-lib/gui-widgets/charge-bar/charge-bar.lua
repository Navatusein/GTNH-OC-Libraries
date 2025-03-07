-- Charge Bar Widget
-- Author: CAHCAHbl4
-- Edit: Navatusein
-- License: MIT
-- Version: 1.2

---@class ChargeBarWidgetConfig
---@field percentName string
---@field chargeName string
---@field arrowCount number
---@field ticksPerArrow number

local chargeBar = {}

---Crate new ChargeBarWidget object from config
---@param config ChargeBarWidgetConfig
---@return ChargeBarWidget
function chargeBar:newFormConfig(config)
  return self:new(config.percentName, config.chargeName, config.arrowCount, config.ticksPerArrow)
end

---Crate new ChargeBarWidget object
---@param percentName string
---@param chargeName string
---@param arrowCount number
---@param ticksPerArrow number
---@return ChargeBarWidget
function chargeBar:new(percentName, chargeName, arrowCount, ticksPerArrow)
  ---@class ChargeBarWidget: Widget
  local obj = {}

  obj.percentName = percentName
  obj.chargeName = chargeName
  obj.arrowCount = arrowCount
  obj.ticksPerArrow = ticksPerArrow

  obj.template = nil
  obj.name = nil

  obj.center = 0
  obj.tick = 1

  ---Init
  ---@param template Template
  function obj:init(template, name)
    self.template = template
    self.name = name
    self.center = math.ceil(template.width / 2)
  end

  ---Render
  ---@param values table<string, string|number|table>
  ---@param y number
  ---@param args string[]
  ---@return string
  function obj:render(values, y, args)
    local level = math.ceil(self.template.width * (values[percentName] / 100))
    local flag = true

    local result = "&&green;"

    for i = 1, self.template.width do
      if flag and i > level then
        result = result.."&&blue;"
      end

      result = result..self:getChar(i, assert(tonumber(values[chargeName])))
    end

    if self.tick >= self.arrowCount * self.ticksPerArrow then
      self.tick = 1
    else
      self.tick = self.tick + 1
    end

    return result
  end

  ---Register key handlers
  ---@return table
  function obj:registerKeyHandlers()
    return {};
  end

  ---Get char for bar
  ---@param index number
  ---@param charge number
  ---@return string
  function obj:getChar(index, charge)
    if charge > 0 then
      local startPosition = self.center - math.ceil(self.arrowCount / 2)

      if (index <= startPosition + math.floor(self.tick / self.ticksPerArrow)) and (index > startPosition) then
        return ">"
      end
    elseif charge < 0 then
      local startPosition = self.center + math.ceil(self.arrowCount / 2)

      if (index >= startPosition - math.floor(self.tick / self.ticksPerArrow)) and (index < startPosition) then
        return "<"
      end
    end

    return " "
  end

  setmetatable(obj, self)
  self.__index = self
  return obj
end

return chargeBar