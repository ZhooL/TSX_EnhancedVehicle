--
-- Mod: TSX_EnhancedVehicle
--
-- Author: ZhooL
-- email: ls19@dark-world.de
-- @Date: 11.01.2019
-- @Version: 1.5.1.2

--[[
CHANGELOG

2019-01-11 - V1.5.1.2
* (shuttle shift) better integration with keyboardSteer. backward looking camera should work again

2019-01-10 - V1.5.1.1
* (shuttle shift) bugfix for shuttle not working when a device with own motor is attached (like the big woodcutter)
* (shuttle shift) reverse lights are now working again when driving backwards. But reverse driving warning sound (beep beep) is still broken.
+ (shuttle shift) added some sounds

2019-01-09 - V1.5.1.0
+ (shuttle shift) added two keybindings (default: insert and delete) for direct selection of forward/reverse driving direction
+ (shuttle shift) implemented a parking break (default key: end). when active, you can't move the vehicle... obviously
+ status of diff locks and drive mode per vehicle are now stored in savegame as well
+ try to disable conflicting keyboardSteer Mod functions (I'm sorry, Mogli12)

2019-01-09 - V1.5.0.2
* bugfix for XML config is being resettet on every game start

2019-01-09 - V1.5.0.1
* fix for log warning about performance of audio sample (wav -> ogg)
* moved all media files to subfolder

2019-01-08 - V1.5.0.0
+ implemented shuttle shift functionality (per vehicle). press assigned key (default: Space) to change driving direction and (default: LCTRL+Space) to turn shuttle shift on/off
+ shuttle shift status per vehicle is stored in savegame
+ added shuttle shift status display left of speedMeter. The green arrow shows the selected driving direction. If shuttle shift is disabled the display turns gray-transparent.
+ added global option "shuttleDefaultIsOn" to choose whether shuttle shift is ON per default when entering "new" vehicles (default: OFF)
* moved differential status display to right-bottom corner of speedMeter

2019-01-06 - V1.4.4.0
* completely rewrote the XML config handling. it's much more flexible now for future usage

2019-01-05 - V1.4.3.0
* replaced ugly text display of diff status by a neat graphic
+ added "clonk" sound when switching diff or drive mode (and global option to turn it off)
+ added global option to choose whether keybindings are displayed in the help menu or not
+ added keybinding (default: KEYPAD *) to reload XML config on the fly

2019-01-04 - V1.4.2.0
+ added "Make Feinstaub great again" feature. vehicles without AdBlue (DEF) will produce more black'n'blue exhaust smoke
* gave keyboard binding display in help menu a very low priority to not disturb the display of more important bindings
* changed the 2WD behavior again. should not be so wobbly any longer.
+ moved global variables like fontSize to XML config

2019-01-03 - V1.4.1.0
* reworked HUD elements positioning. should fix positions once and for all regardless of screen resolutions and GUI scaling (press "KeyPad /" to adept)
* workaround (it displays "0") for attachments without a damage model (no spec_wearable)
* changed the differential behavior for 2WD. this may cause some wobbly side effects on most vehicles but it's more correct now

2019-01-02 - V1.4.0.0
* fixed warning about the background overlay image (png -> dds)
+ config is now stored in XML file
+ position of HUD elements can be moved or enabled/disabled in XML file
* rewrote the key binding/key press stuff
+ key bindings can now be changed in the options menu
+ added config reset functionality and keybinding. use this if you messed up the XML or changed the GUI scale
+ if mod 'keyboardSteerMogli' is detected we move some HUD elements to let them not overlap
* moved the rpm and temperature HUD elements inside the speedmeter
* don't display not working HUD elements as a multiplayer (and not being host) client

2019-01-01 - V1.3.1.1
* bugfix for dedicated servers
* bugfix for clients not reacting on key press (stupid GIANTS engine again)

2019-01-01 - V1.3.1.0
+ added background overlay to make colored text better readable

2018-12-31 - V1.3.0.0
* first release

license: https://creativecommons.org/licenses/by-nc-sa/4.0/
]]--

debug = 0 -- 0=0ff, 1=some, 2=everything, 3=madness
local myName = "TSX_EnhancedVehicle"

-- #############################################################################

TSX_EnhancedVehicle = {}
TSX_EnhancedVehicle.modDirectory  = g_currentModDirectory
TSX_EnhancedVehicle.confDirectory = getUserProfileAppPath().. "modsSettings/TSX_EnhancedVehicle/"

-- for debugging purpose
TSX_dbg = false
TSX_dbg1 = 0
TSX_dbg2 = 0
TSX_dbg3 = 0

-- some global stuff - DONT touch
TSX_EnhancedVehicle.diff_overlayWidth  = 512
TSX_EnhancedVehicle.diff_overlayHeight = 1024
TSX_EnhancedVehicle.dir_overlayWidth  = 64
TSX_EnhancedVehicle.dir_overlayHeight = 256
TSX_EnhancedVehicle.uiScale = 1
if g_gameSettings.uiScale ~= nil then
  if debug > 1 then print("-> uiScale: "..TSX_EnhancedVehicle.uiScale) end
  TSX_EnhancedVehicle.uiScale = g_gameSettings.uiScale
end
TSX_EnhancedVehicle.sections = { 'fuel', 'dmg', 'misc', 'rpm', 'temp', 'diff', 'shuttle' }
TSX_EnhancedVehicle.actions  = { 'TSX_EnhancedVehicle_FD',
                                 'TSX_EnhancedVehicle_RD',
                                 'TSX_EnhancedVehicle_DM',
                                 'TSX_EnhancedVehicle_SHUTTLE_ONOFF',
                                 'TSX_EnhancedVehicle_SHUTTLE_SWITCH',
                                 'TSX_EnhancedVehicle_SHUTTLE_FWD',
                                 'TSX_EnhancedVehicle_SHUTTLE_REV',
                                 'TSX_EnhancedVehicle_SHUTTLE_PARK',
                                 'TSX_EnhancedVehicle_RESET',
                                 'TSX_EnhancedVehicle_RELOAD' }
if TSX_dbg then
  for _, v in pairs({ 'TSX_DBG1_UP', 'TSX_DBG1_DOWN', 'TSX_DBG2_UP', 'TSX_DBG2_DOWN', 'TSX_DBG3_UP', 'TSX_DBG3_DOWN' }) do
    table.insert(TSX_EnhancedVehicle.actions, v)
  end
end

-- some colors
TSX_EnhancedVehicle.color = {
  black  = {       0,       0,       0, 1 },
  white  = {       1,       1,       1, 1 },
  red    = { 255/255,   0/255,   0/255, 1 },
  green  = {   0/255, 255/255,   0/255, 1 },
  blue   = {   0/255,   0/255, 255/255, 1 },
  yellow = { 255/255, 255/255,   0/255, 1 },
  gray   = { 128/255, 128/255, 128/255, 1 },
  dmg    = {  86/255, 142/255,  42/255, 1 },
  fuel   = { 124/255,  90/255,   8/255, 1 },
  adblue = {  48/255,  78/255, 249/255, 1 },
}

-- for overlays
TSX_EnhancedVehicle.overlay = {}

-- load sound effects
if g_dedicatedServerInfo == nil then
  local file, id
  TSX_EnhancedVehicle.sounds = {}
  for _, id in ipairs({"diff_lock", "brakeOn", "brakeOff", "shifter"}) do
    TSX_EnhancedVehicle.sounds[id] = createSample(id)
    file = TSX_EnhancedVehicle.modDirectory.."media/"..id..".ogg"
    loadSample(TSX_EnhancedVehicle.sounds[id], file, false)
  end
end

ksm_loaded = false
if g_modIsLoaded.FS19_KeyboardSteer ~= nil then
  ksm_loaded = true
end

-- #############################################################################

function TSX_EnhancedVehicle.prerequisitesPresent(specializations)
  if debug > 1 then print("-> " .. myName .. ": prerequisites ") end

  return true
end

-- #############################################################################

function TSX_EnhancedVehicle.registerEventListeners(vehicleType)
  if debug > 1 then print("-> " .. myName .. ": registerEventListeners ") end

  for _,n in pairs( { "onLoad", "onPostLoad", "saveToXMLFile", "onUpdate", "onUpdateTick", "onDraw", "onReadStream", "onWriteStream", "onRegisterActionEvents", "onEnterVehicle", "onReverseDirectionChanged" } ) do
    SpecializationUtil.registerEventListener(vehicleType, n, TSX_EnhancedVehicle)
  end
end

-- #############################################################################

function TSX_EnhancedVehicle:activateConfig()
  -- here we will "move" our config from the libConfig internal storage to the variables we actually use

  -- globals
  TSX_EnhancedVehicle.fontSize            = lC:getConfigValue("global.text", "fontSize")
  TSX_EnhancedVehicle.textPadding         = lC:getConfigValue("global.text", "textPadding")
  TSX_EnhancedVehicle.overlayBorder       = lC:getConfigValue("global.text", "overlayBorder")
  TSX_EnhancedVehicle.overlayTransparancy = lC:getConfigValue("global.text", "overlayTransparancy")
  TSX_EnhancedVehicle.showKeysInHelpMenu  = lC:getConfigValue("global.misc", "showKeysInHelpMenu")
  TSX_EnhancedVehicle.soundIsOn           = lC:getConfigValue("global.misc", "soundIsOn")
  TSX_EnhancedVehicle.shuttleDefaultIsOn  = lC:getConfigValue("global.misc", "shuttleDefaultIsOn")

  -- HUD stuff
  for _, section in pairs(TSX_EnhancedVehicle.sections) do
    TSX_EnhancedVehicle[section] = {}
    TSX_EnhancedVehicle[section].enabled = lC:getConfigValue("hud."..section, "enabled")
    TSX_EnhancedVehicle[section].posX    = lC:getConfigValue("hud."..section, "posX")
    TSX_EnhancedVehicle[section].posY    = lC:getConfigValue("hud."..section, "posY")
  end
  TSX_EnhancedVehicle.diff.zoomFactor    = lC:getConfigValue("hud.diff",    "zoomFactor")
  TSX_EnhancedVehicle.shuttle.zoomFactor = lC:getConfigValue("hud.shuttle", "zoomFactor")

  -- Feinstaub
  TSX_EnhancedVehicle.feinstaub = {}
  TSX_EnhancedVehicle.feinstaub.enabled = lC:getConfigValue("feinstaub", "enabled")
  TSX_EnhancedVehicle.feinstaub.min     = lC:getConfigValue("feinstaub", "min")
  TSX_EnhancedVehicle.feinstaub.max     = lC:getConfigValue("feinstaub", "max")
  -- convert string to float to avoid later shader errors
  for _i=1,4 do
    TSX_EnhancedVehicle.feinstaub.min[_i] = tonumber(TSX_EnhancedVehicle.feinstaub.min[_i])
    TSX_EnhancedVehicle.feinstaub.max[_i] = tonumber(TSX_EnhancedVehicle.feinstaub.max[_i])
  end

end

-- #############################################################################

function TSX_EnhancedVehicle:resetConfig()
  if debug > 0 then print("-> " .. myName .. ": resetConfig ") end

  local _x, _y

  if g_gameSettings.uiScale ~= nil then
    TSX_EnhancedVehicle.uiScale = g_gameSettings.uiScale
--    local screenWidth, screenHeight = getScreenModeInfo(getScreenMode())
    if debug > 1 then print("-> uiScale: "..TSX_EnhancedVehicle.uiScale) end
  end

  -- to make life easier
  local baseX = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX
  local baseY = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY

  -- support for keyboardSteer
  ksm = 0
  if ksm_loaded then
    ksm = 0.07 * TSX_EnhancedVehicle.uiScale
    if debug > 1 then print("-> found keyboardSteerMogli. Adjusting some HUD elements") end
  end

  -- start fresh
  lC:clearConfig()

  -- globals
  lC:addConfigValue("global.text", "fontSize", "float",            0.01)
  lC:addConfigValue("global.text", "textPadding", "float",         0.001)
  lC:addConfigValue("global.text", "overlayBorder", "float",       0.003)
  lC:addConfigValue("global.text", "overlayTransparancy", "float", 0.75)
  lC:addConfigValue("global.misc", "showKeysInHelpMenu", "bool",   true)
  lC:addConfigValue("global.misc", "soundIsOn", "bool",            true)
  lC:addConfigValue("global.misc", "shuttleDefaultIsOn", "bool",   false)

  -- fuel
  if g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeIconElement ~= nil then
    _x = baseX + (g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusX / 2.3)
    _y = baseY + (g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusY * 1.8) + ksm
  end
  lC:addConfigValue("hud.fuel", "enabled", "bool", true)
  lC:addConfigValue("hud.fuel", "posX", "float",   _x or 0)
  lC:addConfigValue("hud.fuel", "posY", "float",   _y or 0)

  -- dmg
  if g_currentMission.inGameMenu.hud.speedMeter.damageGaugeIconElement ~= nil then
    _x = baseX - (g_currentMission.inGameMenu.hud.speedMeter.damageGaugeRadiusX / 2.3)
    _y = baseY + (g_currentMission.inGameMenu.hud.speedMeter.damageGaugeRadiusY * 1.8) + ksm
  end
  lC:addConfigValue("hud.dmg", "enabled", "bool", true)
  lC:addConfigValue("hud.dmg", "posX", "float",   _x or 0)
  lC:addConfigValue("hud.dmg", "posY", "float",   _y or 0)

  -- misc
  if g_currentMission.inGameMenu.hud.speedMeter.operatingTimeElement ~= nil then
    _x = baseX
    _y = lC:getConfigValue("global.text", "overlayBorder") * 1
  end
  lC:addConfigValue("hud.misc", "enabled", "bool", true)
  lC:addConfigValue("hud.misc", "posX", "float",   _x or 0)
  lC:addConfigValue("hud.misc", "posY", "float",   _y or 0)

  -- rpm
  if g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX ~= nil then
    _x = baseX - (g_currentMission.inGameMenu.hud.speedMeter.damageGaugeRadiusX / 1.8)
    _y = baseY
  end
  lC:addConfigValue("hud.rpm", "enabled", "bool", true)
  lC:addConfigValue("hud.rpm", "posX", "float",   _x or 0)
  lC:addConfigValue("hud.rpm", "posY", "float",   _y or 0)

  -- temp
  if g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX ~= nil then
    _x = baseX + (g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusX / 1.8)
    _y = baseY
  end
  lC:addConfigValue("hud.temp", "enabled", "bool", true)
  lC:addConfigValue("hud.temp", "posX", "float",   _x or 0)
  lC:addConfigValue("hud.temp", "posY", "float",   _y or 0)

  -- diff
  lC:addConfigValue("hud.diff", "zoomFactor", "float", 18)
  if g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeIconElement ~= nil then
    local _w, _h = getNormalizedScreenValues(TSX_EnhancedVehicle.diff_overlayWidth / lC:getConfigValue("hud.diff", "zoomFactor") * TSX_EnhancedVehicle.uiScale, TSX_EnhancedVehicle.diff_overlayHeight / lC:getConfigValue("hud.diff", "zoomFactor") * TSX_EnhancedVehicle.uiScale)
--    _x = baseX - (_w / 2)
--    _y = baseY + (g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusY * 2.0) + ksm
--    _y = baseY - (_h / 2)
    _x = baseX + (g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusX * 1.18)
    _y = baseY - (g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusY * 1.28)
  end
  lC:addConfigValue("hud.diff", "enabled", "bool", true)
  lC:addConfigValue("hud.diff", "posX", "float",   _x or 0)
  lC:addConfigValue("hud.diff", "posY", "float",   _y or 0)

  -- shuttle shift indicator
  lC:addConfigValue("hud.shuttle", "zoomFactor", "float", 3.5)
  if g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeIconElement ~= nil then
    local _w, _h = getNormalizedScreenValues(TSX_EnhancedVehicle.dir_overlayWidth / lC:getConfigValue("hud.shuttle", "zoomFactor") * TSX_EnhancedVehicle.uiScale, TSX_EnhancedVehicle.dir_overlayHeight / lC:getConfigValue("hud.shuttle", "zoomFactor") * TSX_EnhancedVehicle.uiScale)
--    _x = baseX - (_w / 2)
--    _y = baseY + (g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusY * 1.3)
    _x = baseX - (g_currentMission.inGameMenu.hud.speedMeter.damageGaugeRadiusX * 1.575)
    _y = baseY - (_h / 2)
  end
  lC:addConfigValue("hud.shuttle", "enabled", "bool", true)
  lC:addConfigValue("hud.shuttle", "posX", "float",   _x or 0)
  lC:addConfigValue("hud.shuttle", "posY", "float",   _y or 0)

  -- Feinstaub
  lC:addConfigValue("feinstaub", "enabled", "bool", true)
  lC:addConfigValue("feinstaub", "min", "table",    { 0.5, 0.5,  0.5, 1.5 })
  lC:addConfigValue("feinstaub", "max", "table",    {   0,   0, 0.04,   5 })

end

-- #############################################################################

function TSX_EnhancedVehicle:onLoad(savegame)
  if debug > 1 then print("-> " .. myName .. ": onLoad" .. mySelf(self)) end
end

-- #############################################################################

function TSX_EnhancedVehicle:onPostLoad(savegame)
  if debug > 1 then print("-> " .. myName .. ": onPostLoad" .. mySelf(self)) end

  -- (server) set defaults when vehicle is "new"
  -- vData
  --  1 - frontDiffIsOn
  --  2 - backDiffIsOn
  --  3 - drive mode
  --  4 - shuttle isForward
  --  5 - shuttle inOn
  --  6 - shuttle parkBreakIsOn
  if self.isServer then
    if self.vData == nil then
      self.vData = {}
      self.vData.is   = { true, true, -1, false, true, false }
      self.vData.want = { false, false, 1, true, false, true }
      if TSX_EnhancedVehicle.shuttleDefaultIsOn then
        self.vData.is[5]   = false
        self.vData.want[5] = true
      end
      self.vData.torqueRatio   = { 0.5, 0.5, 0.5 }
      self.vData.maxSpeedRatio = { 1.0, 1.0, 1.0 }
      for _, differential in ipairs(self.spec_motorized.differentials) do
        if differential.diffIndex1 == 1 then -- front
          self.vData.torqueRatio[1]   = differential.torqueRatio
          self.vData.maxSpeedRatio[1] = differential.maxSpeedRatio
        end
        if differential.diffIndex1 == 3 then -- back
          self.vData.torqueRatio[2]   = differential.torqueRatio
          self.vData.maxSpeedRatio[2] = differential.maxSpeedRatio
        end
        if differential.diffIndex1 == 0 and differential.diffIndex1IsWheel == false then -- front_to_back
          self.vData.torqueRatio[3]   = differential.torqueRatio
          self.vData.maxSpeedRatio[3] = differential.maxSpeedRatio
        end
      end
      if debug > 0 then print("--> setup of vData done" .. mySelf(self)) end
    end

    -- load vehicle shuttle status from savegame
    if savegame ~= nil then
      local xmlFile = savegame.xmlFile
      local key     = savegame.key ..".TSX_EnhancedVehicle"

      local _data
      for _, _data in pairs( { {1, 'frontDiffIsOn'}, {2, 'backDiffIsOn'}, {5, 'shuttleIsOn'}, {4, 'shuttleIsForward'}, {6, 'shuttleBreakIsOn'}, {3, 'driveMode'} }) do
        local idx = _data[1]
        local _v
        if idx == 3 then
          _v = getXMLInt(xmlFile, key.."#".. _data[2])
        else
          _v = getXMLBool(xmlFile, key.."#".. _data[2])
        end
        if _v ~= nil then
          if idx == 3 then
            self.vData.is[idx] = -1
            self.vData.want[idx] = _v
            if debug > 1 then print("--> found ".._data[2].."=".._v.." in savegame" .. mySelf(self)) end
          else
            if _v then
              self.vData.is[idx] = false
              self.vData.want[idx] = true
              if debug > 1 then print("--> found ".._data[2].."=true in savegame" .. mySelf(self)) end
            else
              self.vData.is[idx] = true
              self.vData.want[idx] = false
              if debug > 1 then print("--> found ".._data[2].."=false in savegame" .. mySelf(self)) end
            end
          end
        end
      end
    end
  end
end

-- #############################################################################

function TSX_EnhancedVehicle:saveToXMLFile(xmlFile, key)
  if debug > 1 then print("-> " .. myName .. ": saveToXMLFile" .. mySelf(self)) end

  setXMLBool(xmlFile, key.."#frontDiffIsOn",    self.vData.is[1])
  setXMLBool(xmlFile, key.."#backDiffIsOn",     self.vData.is[2])
  setXMLBool(xmlFile, key.."#shuttleIsOn",      self.vData.is[5])
  setXMLBool(xmlFile, key.."#shuttleIsForward", self.vData.is[4])
  setXMLBool(xmlFile, key.."#shuttleBreakIsOn", self.vData.is[6])
  setXMLInt(xmlFile,  key.."#driveMode",        self.vData.is[3])
end

-- #############################################################################

function TSX_EnhancedVehicle:onUpdate(dt)
  if debug > 2 then print("-> " .. myName .. ": onUpdate " .. dt .. ", S: " .. tostring(self.isServer) .. ", C: " .. tostring(self.isClient) .. mySelf(self)) end

  -- hack for keyboardSteer
  if ksm_loaded then
    self.ksmShuttleIsOn = false  -- turn off shuttle control of keyboardSteer
  end

  -- (server) process changes between "is" and "want"
  if self.isServer and self.vData ~= nil then

    -- front diff
    if self.vData.is[1] ~= self.vData.want[1] then
      if self.vData.want[1] then
        updateDifferential(self.rootNode, 0, self.vData.torqueRatio[1], 1)
        if debug > 0 then print("--> ("..self.rootNode..") changed front diff to: ON") end
      else
        updateDifferential(self.rootNode, 0, self.vData.torqueRatio[1], self.vData.maxSpeedRatio[1] * 1000)
        if debug > 0 then print("--> ("..self.rootNode..") changed front diff to: OFF") end
      end
      self.vData.is[1] = self.vData.want[1]
    end

    -- back diff
    if self.vData.is[2] ~= self.vData.want[2] then
      if self.vData.want[2] then
        updateDifferential(self.rootNode, 1, self.vData.torqueRatio[2], 1)
        if debug > 0 then print("--> ("..self.rootNode..") changed back diff to: ON") end
      else
        updateDifferential(self.rootNode, 1, self.vData.torqueRatio[2], self.vData.maxSpeedRatio[2] * 1000)
        if debug > 0 then print("--> ("..self.rootNode..") changed back diff to: OFF") end
      end
      self.vData.is[2] = self.vData.want[2]
    end

    -- wheel drive mode
    if self.vData.is[3] ~= self.vData.want[3] then
      if self.vData.want[3] == 0 then
        updateDifferential(self.rootNode, 2, -0.00001, 1)
        if debug > 0 then print("--> ("..self.rootNode..") changed wheel drive mode to: 2WD") end
      elseif self.vData.want[3] == 1 then
        updateDifferential(self.rootNode, 2, self.vData.torqueRatio[3], 1)
        if debug > 0 then print("--> ("..self.rootNode..") changed wheel drive mode to: 4WD") end
      elseif self.vData.want[3] == 2 then
        updateDifferential(self.rootNode, 2, 1, 0)
        if debug > 0 then print("--> ("..self.rootNode..") changed wheel drive mode to: FWD") end
      end
      self.vData.is[3] = self.vData.want[3]
    end

    -- shuttle shift on/off
    if self.vData.is[5] ~= self.vData.want[5] then
      if self.vData.want[5] then
        -- force setting of drive direction
        self.vData.is[4] = not self.vData.want[4]
        if debug > 0 then print("--> ("..self.rootNode..") changed shuttle shift isOn to: ON") end
      else
        -- reset drive direction to normal
        if self.spec_reverseDriving ~= nil and self.spec_reverseDriving.isReverseDriving ~= nil then
          self.spec_drivable.reverserDirection = self.spec_reverseDriving.isReverseDriving and -1 or 1
        else
          self.spec_drivable.reverserDirection = 1
        end
        if debug > 0 then print("--> ("..self.rootNode..") changed shuttle shift isOn to: OFF") end
      end
      self.vData.is[5] = self.vData.want[5]
    end

    -- shuttle shift switch direction
    if self.vData.is[4] ~= self.vData.want[4] then
      if self.vData.want[4] then
        self.spec_drivable.reverserDirection = 1
        if debug > 0 then print("--> ("..self.rootNode..") changed shuttle shift isForward to: TRUE") end
      else
        self.spec_drivable.reverserDirection = -1
        if debug > 0 then print("--> ("..self.rootNode..") changed shuttle shift isForward to: FALSE") end
      end
      -- turn around driving direction if vehicle is in reverse driving mode
      local _isRD = 1
      if self.spec_reverseDriving ~= nil and self.spec_reverseDriving.isReverseDriving ~= nil then
        _isRD = self.spec_reverseDriving.isReverseDriving and -1 or 1
      end
      self.spec_drivable.reverserDirection = self.spec_drivable.reverserDirection * _isRD
      self.vData.is[4] = self.vData.want[4]
    end

    -- shuttle shift parking break
    if self.vData.is[6] ~= self.vData.want[6] then
      if self.vData.want[6] then
        if debug > 0 then print("--> ("..self.rootNode..") changed shuttle shift breakIsOn to: TRUE") end
      else
        if debug > 0 then print("--> ("..self.rootNode..") changed shuttle shift breakIsOn to: FALSE") end
      end
      self.vData.is[6] = self.vData.want[6]
    end

  end
end

-- #############################################################################

function TSX_EnhancedVehicle:onUpdateTick(dt)
  if debug > 2 then print("-> " .. myName .. ": onUpdateTick " .. dt .. mySelf(self)) end
end

-- #############################################################################

function TSX_EnhancedVehicle:onDraw()
  if debug > 2 then print("-> " .. myName .. ": onDraw, S: " .. tostring(self.isServer) .. ", C: " .. tostring(self.isClient) .. mySelf(self)) end

  -- only on client side and GUI is visible
  if self.isClient and not g_gui:getIsGuiVisible() and self:getIsControlled() then
    local fS = TSX_EnhancedVehicle.fontSize * TSX_EnhancedVehicle.uiScale
    local tP = TSX_EnhancedVehicle.textPadding * TSX_EnhancedVehicle.uiScale

    -- render debug stuff
    if TSX_dbg then
      setTextColor(1,0,0,1)
      setTextAlignment(RenderText.ALIGN_CENTER)
      setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
      setTextBold(true)
      renderText(0.5, 0.5, 0.025, "dbg1: "..TSX_dbg1..", dbg2: "..TSX_dbg2..", dbg3: "..TSX_dbg3)

      -- render some help points into speedMeter
      setTextColor(1,0,0,1)
      setTextAlignment(RenderText.ALIGN_CENTER)
      setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
      setTextBold(false)
      renderText(g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX, g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY, 0.01, "O")
      renderText(g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX + g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusX, g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY + g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusY, 0.01, "O")
      renderText(g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX - g_currentMission.inGameMenu.hud.speedMeter.damageGaugeRadiusX, g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY + g_currentMission.inGameMenu.hud.speedMeter.damageGaugeRadiusY, 0.01, "O")
    end

    -- prepare overlays
    if TSX_EnhancedVehicle.overlay["fuel"] == nil then
      TSX_EnhancedVehicle.overlay["fuel"] = createImageOverlay(TSX_EnhancedVehicle.modDirectory .. "media/overlay_bg.dds")
      setOverlayColor(TSX_EnhancedVehicle.overlay["fuel"], 0, 0, 0, TSX_EnhancedVehicle.overlayTransparancy)
    end
    if TSX_EnhancedVehicle.overlay["dmg"] == nil then
      TSX_EnhancedVehicle.overlay["dmg"] = createImageOverlay(TSX_EnhancedVehicle.modDirectory .. "media/overlay_bg.dds")
      setOverlayColor(TSX_EnhancedVehicle.overlay["dmg"], 0, 0, 0, TSX_EnhancedVehicle.overlayTransparancy)
    end
    if TSX_EnhancedVehicle.overlay["misc"] == nil then
      TSX_EnhancedVehicle.overlay["misc"] = createImageOverlay(TSX_EnhancedVehicle.modDirectory .. "media/overlay_bg.dds")
      setOverlayColor(TSX_EnhancedVehicle.overlay["misc"], 0, 0, 0, TSX_EnhancedVehicle.overlayTransparancy)
    end
    if TSX_EnhancedVehicle.overlay["diff_bg"] == nil then
      TSX_EnhancedVehicle.overlay["diff_bg"] = createImageOverlay(TSX_EnhancedVehicle.modDirectory .. "media/overlay_diff_bg.dds")
      setOverlayColor(TSX_EnhancedVehicle.overlay["diff_bg"], 0, 0, 0, 1)
    end
    if TSX_EnhancedVehicle.overlay["diff_front"] == nil then
      TSX_EnhancedVehicle.overlay["diff_front"] = createImageOverlay(TSX_EnhancedVehicle.modDirectory .. "media/overlay_diff_front.dds")
    end
    if TSX_EnhancedVehicle.overlay["diff_back"] == nil then
      TSX_EnhancedVehicle.overlay["diff_back"] = createImageOverlay(TSX_EnhancedVehicle.modDirectory .. "media/overlay_diff_back.dds")
    end
    if TSX_EnhancedVehicle.overlay["diff_dm"] == nil then
      TSX_EnhancedVehicle.overlay["diff_dm"] = createImageOverlay(TSX_EnhancedVehicle.modDirectory .. "media/overlay_diff_dm.dds")
    end
    if TSX_EnhancedVehicle.overlay["dir_fwd"] == nil then
      TSX_EnhancedVehicle.overlay["dir_fwd"] = createImageOverlay(TSX_EnhancedVehicle.modDirectory .. "media/direction_indicator_fwd.dds")
    end
    if TSX_EnhancedVehicle.overlay["dir_rev"] == nil then
      TSX_EnhancedVehicle.overlay["dir_rev"] = createImageOverlay(TSX_EnhancedVehicle.modDirectory .. "media/direction_indicator_rev.dds")
    end
    if TSX_EnhancedVehicle.overlay["dir_neutral"] == nil then
      TSX_EnhancedVehicle.overlay["dir_neutral"] = createImageOverlay(TSX_EnhancedVehicle.modDirectory .. "media/direction_indicator_neutral.dds")
    end

    -- ### do the fuel stuff ###
    if self.spec_fillUnit ~= nil and TSX_EnhancedVehicle.fuel.enabled then
      -- get values
      fuel_diesel_current = -1
      fuel_adblue_current = -1
      for _, fillUnit in ipairs(self.spec_fillUnit.fillUnits) do
        if fillUnit.fillType == 32 then -- Diesel
          fuel_diesel_max = fillUnit.capacity
          fuel_diesel_current = fillUnit.fillLevel
        end
        if fillUnit.fillType == 33 then -- AdBlue
          fuel_adblue_max = fillUnit.capacity
          fuel_adblue_current = fillUnit.fillLevel
        end
      end

      -- prepare text
      h = 0
      fuel_txt_usage = ""
      fuel_txt_diesel = ""
      fuel_txt_adblue = ""
      if fuel_diesel_current >= 0 then
        fuel_txt_diesel = string.format("%.1f l/%.1f l", fuel_diesel_current, fuel_diesel_max)
        h = h + fS + tP
      end
      if fuel_adblue_current >= 0 then
        fuel_txt_adblue = string.format("%.1f l/%.1f l", fuel_adblue_current, fuel_adblue_max)
        h = h + fS + tP
      end
      if self.spec_motorized.isMotorStarted == true and self.isServer then
        fuel_txt_usage = string.format("%.2f l/h", self.spec_motorized.lastFuelUsage)
        h = h + fS + tP
      end

      -- render overlay
      w = getTextWidth(fS, fuel_txt_diesel)
      tmp = getTextWidth(fS, fuel_txt_adblue)
      if  tmp > w then
        w = tmp
      end
      tmp = getTextWidth(fS, fuel_txt_usage)
      if  tmp > w then
        w = tmp
      end
      renderOverlay(TSX_EnhancedVehicle.overlay["fuel"], TSX_EnhancedVehicle.fuel.posX - TSX_EnhancedVehicle.overlayBorder, TSX_EnhancedVehicle.fuel.posY - TSX_EnhancedVehicle.overlayBorder, w + (TSX_EnhancedVehicle.overlayBorder*2), h + (TSX_EnhancedVehicle.overlayBorder*2))

      -- render text
      tmpY = TSX_EnhancedVehicle.fuel.posY
      setTextAlignment(RenderText.ALIGN_LEFT)
      setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BOTTOM)
      setTextBold(false)
      if fuel_txt_diesel ~= "" then
        setTextColor(unpack(TSX_EnhancedVehicle.color.fuel))
        renderText(TSX_EnhancedVehicle.fuel.posX, tmpY, fS, fuel_txt_diesel)
        tmpY = tmpY + fS + tP
      end
      if fuel_txt_adblue ~= "" then
        setTextColor(unpack(TSX_EnhancedVehicle.color.adblue))
        renderText(TSX_EnhancedVehicle.fuel.posX, tmpY, fS, fuel_txt_adblue)
        tmpY = tmpY + fS + tP
      end
      if fuel_txt_usage ~= "" then
        setTextColor(1,1,1,1)
        renderText(TSX_EnhancedVehicle.fuel.posX, tmpY, fS, fuel_txt_usage)
      end
      setTextColor(1,1,1,1)
    end

    -- ### do the damage stuff ###
    if self.spec_wearable ~= nil and TSX_EnhancedVehicle.dmg.enabled then
      -- prepare text
      h = 0
      dmg_txt = ""
      if self.spec_wearable.totalAmount ~= nil then
        dmg_txt = string.format("%s: %.1f", self.typeDesc, (self.spec_wearable.totalAmount * 100)) .. "%"
        h = h + fS + tP
      end

      dmg_txt2 = ""
      if self.spec_attacherJoints ~= nil then
        getDmg(self.spec_attacherJoints)
      end

      -- render overlay
      w = getTextWidth(fS, dmg_txt)
      tmp = getTextWidth(fS, dmg_txt2) + 0.005
      if tmp > w then
        w = tmp
      end
      renderOverlay(TSX_EnhancedVehicle.overlay["dmg"], TSX_EnhancedVehicle.dmg.posX - TSX_EnhancedVehicle.overlayBorder - w, TSX_EnhancedVehicle.dmg.posY - TSX_EnhancedVehicle.overlayBorder, w + (TSX_EnhancedVehicle.overlayBorder * 2), h + (TSX_EnhancedVehicle.overlayBorder * 2))

      -- render text
      setTextColor(1,1,1,1)
      setTextAlignment(RenderText.ALIGN_RIGHT)
      setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BOTTOM)
      setTextColor(unpack(TSX_EnhancedVehicle.color.dmg))
      setTextBold(false)
      renderText(TSX_EnhancedVehicle.dmg.posX, TSX_EnhancedVehicle.dmg.posY, fS, dmg_txt)
      setTextColor(1,1,1,1)
      renderText(TSX_EnhancedVehicle.dmg.posX, TSX_EnhancedVehicle.dmg.posY + fS + tP, fS, dmg_txt2)
    end

    -- ### do the misc stuff ###
    if self.spec_motorized ~= nil and TSX_EnhancedVehicle.misc.enabled then
      -- prepare text
      misc_txt = string.format("%.1f", self:getTotalMass(true)) .. "t (total: " .. string.format("%.1f", self:getTotalMass()) .. " t)"

      -- render overlay
      w = getTextWidth(fS, misc_txt)
      h = getTextHeight(fS, misc_txt)
      renderOverlay(TSX_EnhancedVehicle.overlay["misc"], TSX_EnhancedVehicle.misc.posX - TSX_EnhancedVehicle.overlayBorder - (w/2), TSX_EnhancedVehicle.misc.posY - TSX_EnhancedVehicle.overlayBorder, w + (TSX_EnhancedVehicle.overlayBorder * 2), h + (TSX_EnhancedVehicle.overlayBorder * 2))

      -- render text
      setTextColor(1,1,1,1)
      setTextAlignment(RenderText.ALIGN_CENTER)
      setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BOTTOM)
      setTextBold(false)
      renderText(TSX_EnhancedVehicle.misc.posX, TSX_EnhancedVehicle.misc.posY, fS, misc_txt)
    end

    -- ### do the rpm stuff ###
    if self.spec_motorized ~= nil and TSX_EnhancedVehicle.rpm.enabled then
      -- prepare text
      rpm_txt = "--\nrpm"
      if self.spec_motorized.isMotorStarted == true then
        rpm_txt = string.format("%i\nrpm", self.spec_motorized.motor.lastMotorRpm)
      end

      -- render text
      setTextColor(1,1,1,1)
      setTextAlignment(RenderText.ALIGN_CENTER)
      setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_TOP)
      setTextBold(true)
      renderText(TSX_EnhancedVehicle.rpm.posX, TSX_EnhancedVehicle.rpm.posY, fS, rpm_txt)
    end

    -- ### do the temperature stuff ###
    if self.spec_motorized ~= nil and TSX_EnhancedVehicle.temp.enabled and self.isServer then
      -- prepare text
      temp_txt = "--\n°C"
      if self.spec_motorized.isMotorStarted == true then
        temp_txt = string.format("%i\n°C", self.spec_motorized.motorTemperature.value)
      end

      -- render text
      setTextColor(1,1,1,1)
      setTextAlignment(RenderText.ALIGN_CENTER)
      setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_TOP)
      setTextBold(true)
      renderText(TSX_EnhancedVehicle.temp.posX, TSX_EnhancedVehicle.temp.posY, fS, temp_txt)
    end

    -- ### do the differential stuff ###
    if self.spec_motorized ~= nil and TSX_EnhancedVehicle.diff.enabled then
      -- prepare text
      _txt = {}
      _txt.color = { "green", "green", "gray" }
      if self.vData ~= nil then
        if self.vData.is[1] then
          _txt.color[1] = "red"
        end
        if self.vData.is[2] then
          _txt.color[2] = "red"
        end
        if self.vData.is[3] == 0 then
          _txt.color[3] = "gray"
        end
        if self.vData.is[3] == 1 then
          _txt.color[3] = "yellow"
        end
        if self.vData.is[3] == 2 then
          _txt.color[3] = "gray"
        end
      end

      -- render overlay
      w, h = getNormalizedScreenValues(TSX_EnhancedVehicle.diff_overlayWidth / TSX_EnhancedVehicle.diff.zoomFactor * TSX_EnhancedVehicle.uiScale, TSX_EnhancedVehicle.diff_overlayHeight / TSX_EnhancedVehicle.diff.zoomFactor * TSX_EnhancedVehicle.uiScale)
      setOverlayColor(TSX_EnhancedVehicle.overlay["diff_front"], unpack(TSX_EnhancedVehicle.color[_txt.color[1]]))
      setOverlayColor(TSX_EnhancedVehicle.overlay["diff_back"],  unpack(TSX_EnhancedVehicle.color[_txt.color[2]]))
      setOverlayColor(TSX_EnhancedVehicle.overlay["diff_dm"],    unpack(TSX_EnhancedVehicle.color[_txt.color[3]]))

      renderOverlay(TSX_EnhancedVehicle.overlay["diff_bg"],    TSX_EnhancedVehicle.diff.posX, TSX_EnhancedVehicle.diff.posY, w, h)
      renderOverlay(TSX_EnhancedVehicle.overlay["diff_front"], TSX_EnhancedVehicle.diff.posX, TSX_EnhancedVehicle.diff.posY, w, h)
      renderOverlay(TSX_EnhancedVehicle.overlay["diff_back"],  TSX_EnhancedVehicle.diff.posX, TSX_EnhancedVehicle.diff.posY, w, h)
      renderOverlay(TSX_EnhancedVehicle.overlay["diff_dm"],    TSX_EnhancedVehicle.diff.posX, TSX_EnhancedVehicle.diff.posY, w, h)
    end

    -- ### do the shuttle shift stuff ###
    if self.vData ~= nil and TSX_EnhancedVehicle.shuttle.enabled then
      local _color = { "gray", "gray", "gray" }
      local _trans = 0.25
      -- prepare
      if self.vData.is[5] then
        if self.vData.is[4] then
          _color = { "green", "gray", "gray" }
          _trans = 1
        end
        if not self.vData.is[4] then
          _color = { "gray", "gray", "green" }
          _trans = 1
        end
        if self.vData.is[6] then
          _color = { "gray", "red", "gray" }
          _trans = 1
        end
      end
      if not self:getIsVehicleControlledByPlayer() then
        _trans = 0.25
      end

      -- render overlay
      w, h = getNormalizedScreenValues(TSX_EnhancedVehicle.dir_overlayWidth / TSX_EnhancedVehicle.shuttle.zoomFactor * TSX_EnhancedVehicle.uiScale, TSX_EnhancedVehicle.dir_overlayHeight / TSX_EnhancedVehicle.shuttle.zoomFactor * TSX_EnhancedVehicle.uiScale)
      local _col = { unpack(TSX_EnhancedVehicle.color[_color[1]]) }
      _col[4] = _trans
      setOverlayColor(TSX_EnhancedVehicle.overlay["dir_fwd"], unpack(_col))

      _col = { unpack(TSX_EnhancedVehicle.color[_color[2]]) }
      _col[4] = _trans
      setOverlayColor(TSX_EnhancedVehicle.overlay["dir_neutral"], unpack(_col))

      _col = { unpack(TSX_EnhancedVehicle.color[_color[3]]) }
      _col[4] = _trans
      setOverlayColor(TSX_EnhancedVehicle.overlay["dir_rev"], unpack(_col))

      renderOverlay(TSX_EnhancedVehicle.overlay["dir_fwd"],     TSX_EnhancedVehicle.shuttle.posX, TSX_EnhancedVehicle.shuttle.posY, w, h)
      renderOverlay(TSX_EnhancedVehicle.overlay["dir_neutral"], TSX_EnhancedVehicle.shuttle.posX, TSX_EnhancedVehicle.shuttle.posY, w, h)
      renderOverlay(TSX_EnhancedVehicle.overlay["dir_rev"],     TSX_EnhancedVehicle.shuttle.posX, TSX_EnhancedVehicle.shuttle.posY, w, h)
    end

    -- reset text stuff to "defaults"
    setTextColor(1,1,1,1)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
    setTextBold(false)
  end

end

-- #############################################################################

function TSX_EnhancedVehicle:onReadStream(streamId, connection)
  if debug > 1 then print("-> " .. myName .. ": onReadStream - " .. streamId .. mySelf(self)) end

  if self.vData == nil then
    self.vData      = {}
    self.vData.is   = {}
    self.vData.want = {}
  end

  -- receive initial data from server
  self.vData.is[1] = streamReadBool(streamId)
  self.vData.is[2] = streamReadBool(streamId)
  self.vData.is[3] = streamReadInt8(streamId)
  self.vData.is[4] = streamReadBool(streamId)
  self.vData.is[5] = streamReadBool(streamId)
  self.vData.is[6] = streamReadBool(streamId)

  if self.isClient then
    self.vData.want = { unpack(self.vData.is) }
  end

--  if debug then print(DebugUtil.printTableRecursively(self.vData, 0, 0, 2)) end
end

-- #############################################################################

function TSX_EnhancedVehicle:onWriteStream(streamId, connection)
  if debug > 1 then print("-> " .. myName .. ": onWriteStream - " .. streamId .. mySelf(self)) end

  -- send initial data to client
  if g_dedicatedServerInfo ~= nil then
    -- when dedicated server then send want array to client cause onUpdate never ran and thus vData "is" is "wrong"
    streamWriteBool(streamId, self.vData.want[1])
    streamWriteBool(streamId, self.vData.want[2])
    streamWriteInt8(streamId, self.vData.want[3])
    streamWriteBool(streamId, self.vData.want[4])
    streamWriteBool(streamId, self.vData.want[5])
    streamWriteBool(streamId, self.vData.want[6])
  else
    streamWriteBool(streamId, self.vData.is[1])
    streamWriteBool(streamId, self.vData.is[2])
    streamWriteInt8(streamId, self.vData.is[3])
    streamWriteBool(streamId, self.vData.is[4])
    streamWriteBool(streamId, self.vData.is[5])
    streamWriteBool(streamId, self.vData.is[6])
  end
end

-- #############################################################################

function TSX_EnhancedVehicle:onEnterVehicle()
  if debug > 1 then print("-> " .. myName .. ": onEnterVehicle" .. mySelf(self)) end

  -- inject feinstaub
  if self.spec_motorized  ~= nil and self.spec_fillUnit ~= nil and TSX_EnhancedVehicle.feinstaub.enabled then
    local adblue = false
    for _, fillUnit in ipairs(self.spec_fillUnit.fillUnits) do
      if fillUnit.fillType == 33 then -- AdBlue
        adblue = true
      end
    end

    if not adblue and self.spec_motorized.exhaustEffects ~= nil then
      if debug > 1 then print("--> found vehicle without AdBlue - modify exhaust") end
      for _, exhaustEffect in ipairs(self.spec_motorized.exhaustEffects) do
        exhaustEffect.minRpmColor = TSX_EnhancedVehicle.feinstaub.min
        exhaustEffect.maxRpmColor = TSX_EnhancedVehicle.feinstaub.max
      end
    end
  end

--print(DebugUtil.printTableRecursively(self.spec_motorized.exhaustEffects, 0, 0, 2))
end

-- #############################################################################

function TSX_EnhancedVehicle:onReverseDirectionChanged()
  if debug > 1 then print("-> " .. myName .. ": onReverseDirectionChanged" .. mySelf(self)) end

  -- if shuttle shift is on then fix stuff after changing driving direction
  if self.vData.is[5] then
    self.spec_drivable.reverserDirection = self.vData.is[4] and 1 or -1
    local _isRD = self.spec_reverseDriving.isReverseDriving and -1 or 1
    self.spec_drivable.reverserDirection = self.spec_drivable.reverserDirection * _isRD
  end

end

-- #############################################################################

function TSX_EnhancedVehicle:onRegisterActionEvents(isSelected, isOnActiveVehicle)
  if debug > 1 then print("-> " .. myName .. ": onRegisterActionEvents " .. tostring(isSelected) .. ", " .. tostring(isOnActiveVehicle) .. ", S: " .. tostring(self.isServer) .. ", C: " .. tostring(self.isClient) .. mySelf(self)) end

  -- continue on client side only
  if not self.isClient then
    return
  end

  -- only in active vehicle and when we control it
  if isOnActiveVehicle and self:getIsControlled() then
    -- we could have more than one event, so prepare a table to store them
    if self.ActionEvents == nil then
      self.ActionEvents = {}
    else
      self:clearActionEventsTable( self.ActionEvents )
    end

    -- attach our actions
    for _ ,actionName in pairs(TSX_EnhancedVehicle.actions) do
      local _, eventName = self:addActionEvent(self.ActionEvents, InputAction[actionName], self, TSX_EnhancedVehicle.onActionCall, false, true, false, true, nil)
      -- help menu priorization
      if g_inputBinding ~= nil and g_inputBinding.events ~= nil and g_inputBinding.events[eventName] ~= nil then
        g_inputBinding.events[eventName].displayPriority = 98
        if actionName == "TSX_EnhancedVehicle_SHUTTLE_SWITCH" and self.vData ~= nil and self.vData.is[5] then g_inputBinding.events[eventName].displayPriority = 3 end
        if actionName == "TSX_EnhancedVehicle_DM" then g_inputBinding.events[eventName].displayPriority = 99 end
        -- don't show certain/all keys in help menu
        if actionName == "TSX_EnhancedVehicle_RESET" or actionName == "TSX_EnhancedVehicle_RELOAD" or not TSX_EnhancedVehicle.showKeysInHelpMenu then
          g_inputBinding.events[eventName].displayIsVisible = false
        end
      end
    end
  end
end

-- #############################################################################

function TSX_EnhancedVehicle:onActionCall(actionName, keyStatus, arg4, arg5, arg6)
  if debug > 1 then print("-> " .. myName .. ": onActionCall " .. actionName .. ", keyStatus: " .. keyStatus .. mySelf(self)) end
  if debug > 2 then
    print(arg4)
    print(arg5)
    print(arg6)
  end

  -- front diff
  if actionName == "TSX_EnhancedVehicle_FD" then
    if TSX_EnhancedVehicle.sounds["diff_lock"] ~= nil and TSX_EnhancedVehicle.soundIsOn and g_dedicatedServerInfo == nil then
      playSample(TSX_EnhancedVehicle.sounds["diff_lock"], 1, 0.5, 0, 0, 0)
    end
    self.vData.want[1] = not self.vData.want[1]
    if self.isClient and not self.isServer then
      self.vData.is[1] = self.vData.want[1]
    end
    TSX_EnhancedVehicle_Event:sendEvent(self, unpack(self.vData.want))
  end

  -- back diff
  if actionName == "TSX_EnhancedVehicle_RD" then
    if TSX_EnhancedVehicle.sounds["diff_lock"] ~= nil and TSX_EnhancedVehicle.soundIsOn and g_dedicatedServerInfo == nil then
      playSample(TSX_EnhancedVehicle.sounds["diff_lock"], 1, 0.5, 0, 0, 0)
    end
    self.vData.want[2] = not self.vData.want[2]
    if self.isClient and not self.isServer then
      self.vData.is[2] = self.vData.want[2]
    end
    TSX_EnhancedVehicle_Event:sendEvent(self, unpack(self.vData.want))
  end

  -- wheel drive mode
  if actionName == "TSX_EnhancedVehicle_DM" then
    if TSX_EnhancedVehicle.sounds["diff_lock"] ~= nil and TSX_EnhancedVehicle.soundIsOn and g_dedicatedServerInfo == nil then
      playSample(TSX_EnhancedVehicle.sounds["diff_lock"], 1, 0.5, 0, 0, 0)
    end
    self.vData.want[3] = self.vData.want[3] + 1
    if self.vData.want[3] > 1 then
      self.vData.want[3] = 0
    end
    if self.isClient and not self.isServer then
      self.vData.is[3] = self.vData.want[3]
    end
    TSX_EnhancedVehicle_Event:sendEvent(self, unpack(self.vData.want))
  end

  -- shuttle mode on/off
  if actionName == "TSX_EnhancedVehicle_SHUTTLE_ONOFF" then
    self.vData.want[5] = not self.vData.want[5]
    if self.isClient and not self.isServer then
      self.vData.is[5] = self.vData.want[5]
    end
    TSX_EnhancedVehicle_Event:sendEvent(self, unpack(self.vData.want))
  end

  -- change driving direction
  if actionName == "TSX_EnhancedVehicle_SHUTTLE_SWITCH" and self.vData.is[5] and not self.vData.is[6] then
    -- play sound effect
    if TSX_EnhancedVehicle.sounds["shifter"] ~= nil and TSX_EnhancedVehicle.soundIsOn and g_dedicatedServerInfo == nil then
      playSample(TSX_EnhancedVehicle.sounds["shifter"], 1, 0.5, 0, 0, 0)
    end
    self.vData.want[4] = not self.vData.want[4]
    if self.isClient and not self.isServer then
      self.vData.is[4] = self.vData.want[4]
    end
    TSX_EnhancedVehicle_Event:sendEvent(self, unpack(self.vData.want))
  end

  -- driving direction forwards
  if actionName == "TSX_EnhancedVehicle_SHUTTLE_FWD" and self.vData.is[5] and not self.vData.want[4] and not self.vData.is[6] then
    if TSX_EnhancedVehicle.sounds["shifter"] ~= nil and TSX_EnhancedVehicle.soundIsOn and g_dedicatedServerInfo == nil then
      playSample(TSX_EnhancedVehicle.sounds["shifter"], 1, 0.5, 0, 0, 0)
    end
    self.vData.want[4] = true
    if self.isClient and not self.isServer then
      self.vData.is[4] = self.vData.want[4]
    end
    TSX_EnhancedVehicle_Event:sendEvent(self, unpack(self.vData.want))
  end

  -- driving direction reverse
  if actionName == "TSX_EnhancedVehicle_SHUTTLE_REV" and self.vData.is[5] and self.vData.want[4] and not self.vData.is[6] then
    if TSX_EnhancedVehicle.sounds["shifter"] ~= nil and TSX_EnhancedVehicle.soundIsOn and g_dedicatedServerInfo == nil then
      playSample(TSX_EnhancedVehicle.sounds["shifter"], 1, 0.5, 0, 0, 0)
    end
    self.vData.want[4] = false
    if self.isClient and not self.isServer then
      self.vData.is[4] = self.vData.want[4]
    end
    TSX_EnhancedVehicle_Event:sendEvent(self, unpack(self.vData.want))
  end

  -- parking brake on/off
  if actionName == "TSX_EnhancedVehicle_SHUTTLE_PARK" and self.vData.is[5] then
    if self.vData.is[6] and TSX_EnhancedVehicle.sounds["brakeOff"] ~= nil and TSX_EnhancedVehicle.soundIsOn and g_dedicatedServerInfo == nil then
      playSample(TSX_EnhancedVehicle.sounds["brakeOff"], 1, 0.1, 0, 0, 0)
    end
    if not self.vData.is[6] and TSX_EnhancedVehicle.sounds["brakeOn"] ~= nil and TSX_EnhancedVehicle.soundIsOn and g_dedicatedServerInfo == nil then
      playSample(TSX_EnhancedVehicle.sounds["brakeOn"], 1, 0.1, 0, 0, 0)
    end
    self.vData.want[6] = not self.vData.want[6]
    if self.isClient and not self.isServer then
      self.vData.is[6] = self.vData.want[6]
    end
    TSX_EnhancedVehicle_Event:sendEvent(self, unpack(self.vData.want))
  end

  -- reset config
  if actionName == "TSX_EnhancedVehicle_RESET" then
    TSX_EnhancedVehicle:resetConfig()
    lC:writeConfig()
    TSX_EnhancedVehicle:activateConfig()
  end

  -- reload config
  if actionName == "TSX_EnhancedVehicle_RELOAD" then
    lC:readConfig()
    TSX_EnhancedVehicle:activateConfig()
  end

  -- debug stuff
  if TSX_dbg then
    -- debug1
    if actionName == "TSX_DBG1_UP" then
      TSX_dbg1 = TSX_dbg1 + 0.01
      updateDifferential(self.rootNode, 2, TSX_dbg1, TSX_dbg2)
    end
    if actionName == "TSX_DBG1_DOWN" then
      TSX_dbg1 = TSX_dbg1 - 0.01
      updateDifferential(self.rootNode, 2, TSX_dbg1, TSX_dbg2)
    end
    -- debug2
    if actionName == "TSX_DBG2_UP" then
      TSX_dbg2 = TSX_dbg2 + 0.01
      updateDifferential(self.rootNode, 2, TSX_dbg1, TSX_dbg2)
    end
    if actionName == "TSX_DBG2_DOWN" then
      TSX_dbg2 = TSX_dbg2 - 0.01
      updateDifferential(self.rootNode, 2, TSX_dbg1, TSX_dbg2)
    end
    -- debug3
    if actionName == "TSX_DBG3_UP" then
      TSX_dbg3 = TSX_dbg3 + 0.01
    end
    if actionName == "TSX_DBG3_DOWN" then
      TSX_dbg3 = TSX_dbg3 - 0.01
    end
  end

end

-- #############################################################################

-- what a crap... we've to hook into the updateWheelsPhysics function to prevent the vehicle to drive in the wrong direction in shuttle mode
function TSX_EnhancedVehicle:updateWheelsPhysics( originalFunction, dt, currentSpeed, acceleration, doHandbrake, stopAndGoBraking )
--print("function WheelsUtil.updateWheelsPhysics("..tostring(self)..", "..tostring(dt)..", "..tostring(currentSpeed)..", "..tostring(acceleration)..", "..tostring(doHandbrake)..", "..tostring(stopAndGoBraking))

  local brakeLights = false
  local reverseLights = false
  if self.vData ~= nil and self.vData.is[5] then
    if self:getIsVehicleControlledByPlayer() and self:getIsMotorStarted() then
      -- are we driving backwards?
      if currentSpeed <= -0.0003 then
        reverseLights = true
        if ksm_loaded then
          self.ksmMovingDir = -1
          self:ksmSetState( "ksmCamFwd", false )
        end
      end
      -- are we driving forwards?
      if currentSpeed >= 0.0003 and ksm_loaded then
        self.ksmMovingDir = 1
        self:ksmSetState( "ksmCamFwd", true )
      end
      if self.vData.is[6] then
        brakeLights = true
        if currentSpeed >= -0.0003 and currentSpeed <= 0.0003 then
          brakeLights = false
        end
        acceleration = 0
        currentSpeed = 0
      else
        if acceleration < -0.001 then
          if self.vData.is[4] and currentSpeed <= 0.0003 then
--            print("NO FWD "..tostring(currentSpeed)..", "..tostring(acceleration)..", "..tostring(doHandbrake)..", "..tostring(stopAndGoBraking))
            acceleration = 0
            currentSpeed = 0
            brakeLights = true
          end
          if not self.vData.is[4] and currentSpeed >= -0.0003 then
--            print("NO RWS "..tostring(currentSpeed)..", "..tostring(acceleration)..", "..tostring(doHandbrake)..", "..tostring(stopAndGoBraking))
            acceleration = 0
            currentSpeed = 0
            brakeLights = true
          end
        end
      end
    end
  end

  -- call the original function to do the actual physics stuff
  local state, result = pcall( originalFunction, self, dt, currentSpeed, acceleration, doHandbrake, stopAndGoBraking )
  if not ( state ) then
    print("Ooops in updateWheelsPhysics :" .. tostring(result))
  end

  if brakeLights and self.setBrakeLightsVisibility ~= nil then
    self:setBrakeLightsVisibility(true)
  end
  if reverseLights and self.setReverseLightsVisibility ~= nil then
    self:setReverseLightsVisibility(true)
  end

  return result
end
WheelsUtil.updateWheelsPhysics = Utils.overwrittenFunction( WheelsUtil.updateWheelsPhysics, TSX_EnhancedVehicle.updateWheelsPhysics )

-- #############################################################################

function getDmg(start)
  if start.spec_attacherJoints.attachedImplements ~= nil then
    for _, implement in pairs(start.spec_attacherJoints.attachedImplements) do
      local tA = 0
      if implement.object.spec_wearable ~= nil and implement.object.spec_wearable.totalAmount ~= nil then
        tA = implement.object.spec_wearable.totalAmount
      end
      dmg_txt2 = string.format("%s: %.1f", implement.object.typeDesc, (tA * 100)) .. "%\n" .. dmg_txt2
      h = h + (TSX_EnhancedVehicle.fontSize + TSX_EnhancedVehicle.textPadding) * TSX_EnhancedVehicle.uiScale
      if implement.object.spec_attacherJoints ~= nil then
        getDmg(implement.object)
      end
    end
  end
end

-- #############################################################################

function mySelf(obj)
  return " (rootNode: " .. obj.rootNode .. ", typeName: " .. obj.typeName .. ", typeDesc: " .. obj.typeDesc .. ")"
end

-- #############################################################################
