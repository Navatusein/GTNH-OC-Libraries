local classBuilder = require("lib.class-builder.index")

---@class Handler
local handler = {}

---@return Handler
function handler:constructor()
  return self
end

---Log
---@param logger Logger
---@param level "debug"|"info"|"warning"|"error"
---@param message string
function handler:log(logger, level, message)
  
end

return classBuilder.createClass(handler, handler.constructor)