local classBuilder = {}

---@class ClassBuilder<ClassType, ConstructorType>: {new: ConstructorType}

--- Creates a new class with optional inheritance and metamethods support
---@generic ClassType
---@generic ConstructorType
---@param class ClassType The table that will serve as the class prototype
---@param constructorType ConstructorType The function to be used as the class constructor
---@param baseClass? table An optional base class to inherit from
---@return ClassBuilder<ClassType, ConstructorType> Returns a class builder with a `new` method
function classBuilder.createClass(class, constructorType, baseClass)
  local builder = {}

  if baseClass then
    setmetatable(class, { __index = baseClass })
  end

  function builder:new(...)
    local instance = setmetatable({}, {
      __index = class,

      __tostring = function(obj)
        return obj.toString and obj:toString() or "<object>"
      end,

      __len = function(obj)
        return obj.len and obj:len() or -1
      end,

      __concat = function(a, b)
        return tostring(a)..tostring(b)
      end,
    })

    instance:constructor(...)

    return instance
  end

  return builder
end

return classBuilder
