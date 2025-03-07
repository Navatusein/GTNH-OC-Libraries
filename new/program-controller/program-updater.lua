local event = require("event")
local term = require("term")
local internet = require("internet")
local shell = require("shell")
local filesystem = require("filesystem")
local computer = require("computer")


local classBuilder = require("lib.class-builder.index")

---@class ProgramUpdater
---@field program Program
---@field interval number
local programUpdater = {}

---@return ProgramUpdater
function programUpdater:constructor(program)
  self.program = program
  self.interval = 3600

  return self
end

---Get timer for check autoupdate
---@return function callback
---@return number times
---@return number interval
function programUpdater:checkUpdateTimer()
  local isUpdateNeededNotified = false

  local callback = function ()
    if isUpdateNeededNotified == true then
      return
    end

    local isUpdateNeeded, isConfigUpdateNeeded, remoteVersion = self:isUpdateNeeded()

    if isUpdateNeededNotified == false and isUpdateNeeded == true then
      event.push("log_warning", "[Autoupdate] New version released, update available.");
      isUpdateNeededNotified = true
    end
  end

  return callback, math.huge, self.interval
end

---Try auto update program
function programUpdater:autoUpdate()
  local isUpdateNeeded, isConfigUpdateNeeded, remoteVersion = self:isUpdateNeeded()
  local currentVersion = self.program.version ~= nil and self.program.version.programVersion or "nil"

  term.setCursor(1, 1)
  term.write("Current version: "..currentVersion.."\n")
  term.write("Check for new version...\n")

  if isUpdateNeeded == false or remoteVersion == nil then
    term.write("Current version is latest\n")
    os.sleep(3)
    term.clear()
    return
  end

  term.clear()
  term.write("Find new version: "..remoteVersion.programVersion.."\n")

  if isConfigUpdateNeeded then
    term.write("This update changes the format of the configuration file.\n")
    term.write("It will be necessary to manually overwrite the configuration file.\n")
  end

  term.write("Do you want to update [y/n]?\n")
  term.write("==>")

  local userInput = io.read()

  if string.lower(userInput) ~= "y" then
    return
  end

  self:tryDownloadTarUtility()

  local url = "https://github.com/"..self.program.repository.."/releases/latest/download/"..self.program.archiveName..".tar"

  term.clear()
  term.write("Updating to version "..remoteVersion.programVersion.."\n")

  self:downloadAndInstall(url)

  if isConfigUpdateNeeded then
    event.push("log_warning", "[Autoupdate] The format of the configs has been updated. It is necessary to manually rewrite the configuration file.");

    term.write("The format of the configs has been updated. It is necessary to manually rewrite the configuration file.\n")
    term.write("After rewriting the configuration file, do not forget to restart your computer.\n")
    term.write("Press [Enter] to confirm")

    term.read()
  else
    shell.execute("mv config.old.lua config.lua")
  end

  term.clear()
  term.write("Update completed\n")
  os.sleep(3)

  if isConfigUpdateNeeded == false then
    computer.shutdown(true)
    return
  end

  self.program:exit()
end

---Get latest version number
---@return ProgramVersion
---@private
function programUpdater:getLatestVersionNumber()
  local request = internet.request("https://raw.githubusercontent.com/"..self.program.repository.."/refs/heads/main/version.lua")
  local result = ""

  for chunk in request do
    result = result..chunk
  end

  return load(result)()
end

---Check if update is needed
---@return boolean # Need program update
---@return boolean # Need config update
---@return ProgramVersion|nil # Remote version
---@private
function programUpdater:isUpdateNeeded()
  if self.program.version == nil or internet == nil then
    return false, false, nil
  end

  local remoteVersion = programUpdater:getLatestVersionNumber()

  local currentProgramVersion = self.program.version.programVersion:gsub("[%D]", "")
  local latestProgramVersion = remoteVersion.programVersion:gsub("[%D]", "")

  local isUpdateNeeded = latestProgramVersion > currentProgramVersion
  local isConfigUpdateNeeded = remoteVersion.configVersion > self.program.version.configVersion

  return isUpdateNeeded, isConfigUpdateNeeded, remoteVersion
end

---Download and install tar utility if not installed
---@private
function programUpdater:tryDownloadTarUtility()
  if filesystem.exists("/bin/tar.lua") then
    return
  end

  local tarManUrl = "https://raw.githubusercontent.com/mpmxyz/ocprograms/master/usr/man/tar.man"
  local tarBinUrl = "https://raw.githubusercontent.com/mpmxyz/ocprograms/master/home/bin/tar.lua"

  shell.setWorkingDirectory("/usr/man")
  shell.execute("wget -fq "..tarManUrl)
  shell.setWorkingDirectory("/bin")
  shell.execute("wget -fq "..tarBinUrl)
end

---Download and install latest version
---@param url string
---@private
function programUpdater:downloadAndInstall(url)
  shell.setWorkingDirectory("/home")
  shell.execute("mv config.lua config.old.lua")
  shell.execute("wget -fq "..url.." program.tar")
  shell.execute("tar -xf program.tar")
  shell.execute("rm program.tar")
end


return classBuilder.createClass(programUpdater, programUpdater.constructor)