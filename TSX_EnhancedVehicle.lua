--
-- Mod: TSX_EnhancedVehicle
--
-- Author: ZhooL
-- email: ls19@dark-world.de
-- @Date: 02.01.2019
-- @Version: 1.4.0.0 

-- CHANGELOG
--
-- 2019-01-02 - V1.4.0.0
-- * fixed warning about the background overlay image (png -> dds)
-- + config is now stored in XML file
-- + position of HUD elements can be moved or enabled/disabled in XML file
-- * rewrote the key binding/key press stuff
-- + key bindings can now be changed in the options menu
-- + added config reset functionality and keybinding
-- + if mod 'keyboardSteerMogli' is detected we move some HUD elements to let them not overlap
--
-- 2019-01-01 - V1.3.1.1
-- * bugfix for dedicated servers
-- * bugfix for clients not reacting on key press (stupid GIANTS engine again)
--
-- 2019-01-01 - V1.3.1.0
-- + added background overlay to make colored text better readable
-- 
-- 2018-12-31 - V1.3.0.0
-- * first release

debug = 0 -- 0=0ff, 1=some, 2=everything, 3=madness
local myName = "TSX_EnhancedVehicle"

-- #############################################################################

TSX_EnhancedVehicle = {}
TSX_EnhancedVehicle.modDirectory  = g_currentModDirectory;
TSX_EnhancedVehicle.confDirectory = getUserProfileAppPath().. "modsSettings/TSX_EnhancedVehicle/"; 

-- some global stuff
TSX_EnhancedVehicle.uiScale = 1
if g_gameSettings.uiScale ~= nil then
  if debug > 1 then print("-> uiScale: "..TSX_EnhancedVehicle.uiScale) end
  TSX_EnhancedVehicle.uiScale = g_gameSettings.uiScale
end
TSX_EnhancedVehicle.fontSize            = 0.01  * TSX_EnhancedVehicle.uiScale 
TSX_EnhancedVehicle.textPadding         = 0.001 * TSX_EnhancedVehicle.uiScale
TSX_EnhancedVehicle.overlayBorder       = 0.003 * TSX_EnhancedVehicle.uiScale
TSX_EnhancedVehicle.overlayTransparancy = 0.75
TSX_EnhancedVehicle.actions             = { 'TSX_EnhancedVehicle_FD', 'TSX_EnhancedVehicle_RD', 'TSX_EnhancedVehicle_DM', 'TSX_EnhancedVehicle_RESET' }
TSX_EnhancedVehicle.sections            = { 'fuel', 'dmg', 'misc', 'rpm', 'temp', 'diff' }

-- some colors
TSX_EnhancedVehicle.color = {
  white  = {       1,       1,       1, 1 },
  red    = { 255/255,   0/255,   0/255, 1 },
  green  = {   0/255, 255/255,   0/255, 1 },
  blue   = {   0/255,   0/255, 255/255, 1 },
  yellow = { 255/255, 255/255,   0/255, 1 },
  dmg    = {  86/255, 142/255,  42/255, 1 },
  fuel   = { 124/255,  90/255,   8/255, 1 },
  adblue = {  48/255,  78/255, 249/255, 1 },
}

-- for overlays
TSX_EnhancedVehicle.overlay = {}

-- for vehicle status and data information
TSX_EnhancedVehicle.vData = {}

-- for tracking key press
TSX_EnhancedVehicle.keyPressed = {}
TSX_EnhancedVehicle.keyPressed.diff_front = false
TSX_EnhancedVehicle.keyPressed.diff_back  = false
TSX_EnhancedVehicle.keyPressed.wd_mode    = false

-- #############################################################################

function TSX_EnhancedVehicle:readConfig()
  if debug > 0 then print("-> " .. myName .. ": readConfig ") end

  -- skip on dedicated servers
  if g_dedicatedServerInfo ~= nil then
    return
  end

  local v1
  local v2
  local v3
  
  local file = TSX_EnhancedVehicle.confDirectory..myName..".xml"
  local xml
  if not fileExists(file) then
    TSX_EnhancedVehicle:resetConfig()
    TSX_EnhancedVehicle:writeConfig()
  else
    -- load existing XMF file
    xml = loadXMLFile("TSX_EnhancedVehicle_XML", file, "TSX_EnhancedVehicleSettings");

    for _, section in ipairs(TSX_EnhancedVehicle.sections) do
      group = "hud." .. section
      groupNameTag = string.format("TSX_EnhancedVehicleSettings.%s(%d)", group, 0) 
      v1 =  getXMLBool(xml, groupNameTag.. "#enabled")
      v2 = getXMLFloat(xml, groupNameTag.. "#posX")
      v3 = getXMLFloat(xml, groupNameTag.. "#posY")
      if v1 == nil or v2 == nil or v3 == nil then
        if debug > 1 then print("--> can't find values for '"..section.."'. Resetting config.") end
        TSX_EnhancedVehicle:resetConfig()
      else
        if debug > 1 then print("--> found values for '"..section.."'. v1: "..bool_to_number(v1)..", v2: "..v2..", v3: "..v3) end
        TSX_EnhancedVehicle[section] = {}
        TSX_EnhancedVehicle[section].enabled = v1
        TSX_EnhancedVehicle[section].posX = v2
        TSX_EnhancedVehicle[section].posY = v3
      end          
    end
  end
end

-- #############################################################################

function TSX_EnhancedVehicle:writeConfig()
  if debug > 0 then print("-> " .. myName .. ": writeConfig ") end

  -- skip on dedicated servers
  if g_dedicatedServerInfo ~= nil then
    return
  end

  createFolder(getUserProfileAppPath().. "modsSettings/");
  createFolder(TSX_EnhancedVehicle.confDirectory);

  local file = TSX_EnhancedVehicle.confDirectory..myName..".xml"
  local xml
  local groupNameTag
  local group
  xml = createXMLFile("TSX_EnhancedVehicle_XML", file, "TSX_EnhancedVehicleSettings");

  for _, section in ipairs(TSX_EnhancedVehicle.sections) do
    group = "hud." .. section
    groupNameTag = string.format("TSX_EnhancedVehicleSettings.%s(%d)", group, 0) 
    setXMLBool(xml,  groupNameTag .. "#enabled", TSX_EnhancedVehicle[section].enabled);
    setXMLFloat(xml, groupNameTag .. "#posX",    TSX_EnhancedVehicle[section].posX);
    setXMLFloat(xml, groupNameTag .. "#posY",    TSX_EnhancedVehicle[section].posY);
    if debug > 1 then print("--> wrote values for '"..section.."'. v1: "..bool_to_number(TSX_EnhancedVehicle[section].enabled)..", v2: "..TSX_EnhancedVehicle[section].posX..", v3: "..TSX_EnhancedVehicle[section].posY) end
  end

  saveXMLFile(xml)
end

-- #############################################################################

function TSX_EnhancedVehicle:resetConfig()
  if debug > 0 then print("-> " .. myName .. ": resetConfig ") end

  if g_gameSettings.uiScale ~= nil then
    if debug > 1 then print("-> uiScale: "..TSX_EnhancedVehicle.uiScale) end
    TSX_EnhancedVehicle.uiScale = g_gameSettings.uiScale
  end

  ksm = 0
  if g_modIsLoaded.FS19_KeyboardSteer ~= nil then
    ksm = 0.5
    if debug > 1 then print("-> found keyboardSteerMogli. Adjusting some HUD elements") end
  end

  -- fuel
  if TSX_EnhancedVehicle.fuel == nil then
    TSX_EnhancedVehicle.fuel = {}  
    TSX_EnhancedVehicle.fuel.enabled = false  
    TSX_EnhancedVehicle.fuel.posX = 0
    TSX_EnhancedVehicle.fuel.posY = 0
    if g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeIconElement ~= nil then
      TSX_EnhancedVehicle.fuel.enabled = true  
      TSX_EnhancedVehicle.fuel.posX = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX + ( 0.018 * TSX_EnhancedVehicle.uiScale )
      TSX_EnhancedVehicle.fuel.posY = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY + ( (1.8 + ksm)  * g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusY ) 
      if debug > 1 then print("--> reset values for 'fuel'. v1: "..bool_to_number(TSX_EnhancedVehicle.fuel.enabled)..", v2: "..TSX_EnhancedVehicle.fuel.posX..", v3: "..TSX_EnhancedVehicle.fuel.posY) end
    end
  end
  -- damage
  if TSX_EnhancedVehicle.dmg == nil then
    TSX_EnhancedVehicle.dmg = {}  
    TSX_EnhancedVehicle.dmg.enabled = false  
    TSX_EnhancedVehicle.dmg.posX = 0
    TSX_EnhancedVehicle.dmg.posY = 0
    if g_currentMission.inGameMenu.hud.speedMeter.damageGaugeIconElement ~= nil then
      TSX_EnhancedVehicle.dmg.enabled = true
      TSX_EnhancedVehicle.dmg.posX = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX - ( 0.018 * TSX_EnhancedVehicle.uiScale )
      TSX_EnhancedVehicle.dmg.posY = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY + ( (1.8 + ksm) * g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusY )
      if debug > 1 then print("--> reset values for 'dmg'. v1: "..bool_to_number(TSX_EnhancedVehicle.dmg.enabled)..", v2: "..TSX_EnhancedVehicle.dmg.posX..", v3: "..TSX_EnhancedVehicle.dmg.posY) end
    end
  end
  -- misc
  if TSX_EnhancedVehicle.misc == nil then
    TSX_EnhancedVehicle.misc = {}  
    TSX_EnhancedVehicle.misc.enabled = false  
    TSX_EnhancedVehicle.misc.posX = 0
    TSX_EnhancedVehicle.misc.posY = 0
    if g_currentMission.inGameMenu.hud.speedMeter.operatingTimeElement ~= nil then
      TSX_EnhancedVehicle.misc.enabled = true
      TSX_EnhancedVehicle.misc.posX = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX
      TSX_EnhancedVehicle.misc.posY = TSX_EnhancedVehicle.overlayBorder * 1
      if debug > 1 then print("--> reset values for 'misc'. v1: "..bool_to_number(TSX_EnhancedVehicle.misc.enabled)..", v2: "..TSX_EnhancedVehicle.misc.posX..", v3: "..TSX_EnhancedVehicle.misc.posY) end
    end
  end
  -- rpm
  if TSX_EnhancedVehicle.rpm == nil then
    TSX_EnhancedVehicle.rpm = {}  
    TSX_EnhancedVehicle.rpm.enabled = false  
    TSX_EnhancedVehicle.rpm.posX = 0
    TSX_EnhancedVehicle.rpm.posY = 0
    if g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX ~= nil then
      TSX_EnhancedVehicle.rpm.enabled = true
      TSX_EnhancedVehicle.rpm.posX = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX - ( 0.021 * TSX_EnhancedVehicle.uiScale )
      TSX_EnhancedVehicle.rpm.posY = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY - ( 0.0075 * TSX_EnhancedVehicle.uiScale )          
      if debug > 1 then print("--> reset values for 'rpm'. v1: "..bool_to_number(TSX_EnhancedVehicle.rpm.enabled)..", v2: "..TSX_EnhancedVehicle.rpm.posX..", v3: "..TSX_EnhancedVehicle.rpm.posY) end
    end
  end
  -- temperature
  if TSX_EnhancedVehicle.temp == nil then
    TSX_EnhancedVehicle.temp = {}  
    TSX_EnhancedVehicle.temp.enabled = false  
    TSX_EnhancedVehicle.temp.posX = 0
    TSX_EnhancedVehicle.temp.posY = 0
    if g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX ~= nil then
      TSX_EnhancedVehicle.temp.enabled = true
      TSX_EnhancedVehicle.temp.posX = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX + ( 0.021 * TSX_EnhancedVehicle.uiScale )
      TSX_EnhancedVehicle.temp.posY = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY - ( 0.0075 * TSX_EnhancedVehicle.uiScale )
      if debug > 1 then print("--> reset values for 'temp'. v1: "..bool_to_number(TSX_EnhancedVehicle.temp.enabled)..", v2: "..TSX_EnhancedVehicle.temp.posX..", v3: "..TSX_EnhancedVehicle.temp.posY) end
    end
  end
  -- diff
  if TSX_EnhancedVehicle.diff == nil then
    TSX_EnhancedVehicle.diff = {}  
    TSX_EnhancedVehicle.diff.enabled = false  
    TSX_EnhancedVehicle.diff.posX = 0
    TSX_EnhancedVehicle.diff.posY = 0
    if g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeIconElement ~= nil then
      TSX_EnhancedVehicle.diff.enabled = true
      TSX_EnhancedVehicle.diff.posX = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX + ( 0.035 * TSX_EnhancedVehicle.uiScale )
      TSX_EnhancedVehicle.diff.posY = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY + ( (2.5 + ksm) * g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusY )
      if debug > 1 then print("--> reset values for 'diff'. v1: "..bool_to_number(TSX_EnhancedVehicle.diff.enabled)..", v2: "..TSX_EnhancedVehicle.diff.posX..", v3: "..TSX_EnhancedVehicle.diff.posY) end
    end
  end

  TSX_EnhancedVehicle:writeConfig()
end

-- #############################################################################

function TSX_EnhancedVehicle.prerequisitesPresent(specializations)
  if debug > 1 then print("-> " .. myName .. ": prerequisites ") end
  
  return true
end

-- #############################################################################

function TSX_EnhancedVehicle.registerEventListeners(vehicleType)
  if debug > 1 then print("-> " .. myName .. ": registerEventListeners ") end
    
  for _,n in pairs( { "onLoad", "onPostLoad", "onUpdate", "onUpdateTick", "onDraw", "onReadStream", "onWriteStream", "onRegisterActionEvents" } ) do
    SpecializationUtil.registerEventListener(vehicleType, n, TSX_EnhancedVehicle)
  end 
end

-- #############################################################################

function TSX_EnhancedVehicle:onLoad(savegame)
  if debug > 1 then print("-> " .. myName .. ": onLoad" .. mySelf(self)) end

end

-- #############################################################################

function TSX_EnhancedVehicle:onPostLoad(savegame)
  if debug > 1 then print("-> " .. myName .. ": onPostLoad" .. mySelf(self)) end

  -- (server) set defaults when vehicle is "new"
  if self.isServer then
    if self.vData == nil then
      self.vData = {}
      self.vData.is   = { true, true, -1 } 
      self.vData.want = { false, false, 1 }
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
      if debug > 0 then print("--> setup of differentials done" .. mySelf(self)) end            
    end
  end

end

-- #############################################################################

function TSX_EnhancedVehicle:onUpdate(dt)
  if debug > 2 then print("-> " .. myName .. ": onUpdate " .. dt .. ", S: " .. bool_to_number(self.isServer) .. ", C: " .. bool_to_number(self.isClient) .. mySelf(self)) end

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
        updateDifferential(self.rootNode, 2, 0.9, 1)
        if debug > 0 then print("--> ("..self.rootNode..") changed wheel drive mode to: 2WD") end
      elseif self.vData.want[3] == 1 then
        updateDifferential(self.rootNode, 2, self.vData.torqueRatio[3], 1)
        if debug > 0 then print("--> ("..self.rootNode..") changed wheel drive mode to: 4WD") end
      elseif self.vData.want[3] == 2 then
        updateDifferential(self.rootNode, 2, 1, 1)
        if debug > 0 then print("--> ("..self.rootNode..") changed wheel drive mode to: FWD") end
      end
      self.vData.is[3] = self.vData.want[3]
    end
  end

end

-- #############################################################################

function TSX_EnhancedVehicle:onUpdateTick(dt)
  if debug > 2 then print("-> " .. myName .. ": onUpdateTick " .. dt .. mySelf(self)) end

end

-- #############################################################################

function TSX_EnhancedVehicle:onDraw()
  if debug > 2 then print("-> " .. myName .. ": onDraw, S: " .. bool_to_number(self.isServer) .. ", C: " .. bool_to_number(self.isClient) .. mySelf(self)) end

  -- only on client side and GUI is visible
  if self.isClient and not g_gui:getIsGuiVisible() then

    -- prepare overlays
    if TSX_EnhancedVehicle.overlay["fuel"] == nil then
      TSX_EnhancedVehicle.overlay["fuel"] = createImageOverlay(TSX_EnhancedVehicle.modDirectory .. "overlay_bg.dds")
      setOverlayColor(TSX_EnhancedVehicle.overlay["fuel"], 0, 0, 0, TSX_EnhancedVehicle.overlayTransparancy)
    end
    if TSX_EnhancedVehicle.overlay["dmg"] == nil then
      TSX_EnhancedVehicle.overlay["dmg"] = createImageOverlay(TSX_EnhancedVehicle.modDirectory .. "overlay_bg.dds")
      setOverlayColor(TSX_EnhancedVehicle.overlay["dmg"], 0, 0, 0, TSX_EnhancedVehicle.overlayTransparancy)
    end
    if TSX_EnhancedVehicle.overlay["diff"] == nil then
      TSX_EnhancedVehicle.overlay["diff"] = createImageOverlay(TSX_EnhancedVehicle.modDirectory .. "overlay_bg.dds")
      setOverlayColor(TSX_EnhancedVehicle.overlay["diff"], 0, 0, 0, TSX_EnhancedVehicle.overlayTransparancy)
    end
    if TSX_EnhancedVehicle.overlay["misc"] == nil then
      TSX_EnhancedVehicle.overlay["misc"] = createImageOverlay(TSX_EnhancedVehicle.modDirectory .. "overlay_bg.dds")
      setOverlayColor(TSX_EnhancedVehicle.overlay["misc"], 0, 0, 0, TSX_EnhancedVehicle.overlayTransparancy)
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
        h = h + TSX_EnhancedVehicle.fontSize + TSX_EnhancedVehicle.textPadding 
      end
      if fuel_adblue_current >= 0 then
        fuel_txt_adblue = string.format("%.1f l/%.1f l", fuel_adblue_current, fuel_adblue_max)
        h = h + TSX_EnhancedVehicle.fontSize + TSX_EnhancedVehicle.textPadding 
      end
      if self.spec_motorized.isMotorStarted == true and self.isServer then
        fuel_txt_usage = string.format("%.2f l/h", self.spec_motorized.lastFuelUsage)
        h = h + TSX_EnhancedVehicle.fontSize + TSX_EnhancedVehicle.textPadding 
      end 

      -- render overlay
      w = getTextWidth(TSX_EnhancedVehicle.fontSize, fuel_txt_diesel)
      tmp = getTextWidth(TSX_EnhancedVehicle.fontSize, fuel_txt_adblue) 
      if  tmp > w then
        w = tmp
      end
      tmp = getTextWidth(TSX_EnhancedVehicle.fontSize, fuel_txt_usage) 
      if  tmp > w then
        w = tmp
      end
      renderOverlay(TSX_EnhancedVehicle.overlay["fuel"], TSX_EnhancedVehicle.fuel.posX - TSX_EnhancedVehicle.overlayBorder, TSX_EnhancedVehicle.fuel.posY - TSX_EnhancedVehicle.overlayBorder, w + (TSX_EnhancedVehicle.overlayBorder*2), h + (TSX_EnhancedVehicle.overlayBorder*2))
       
      -- render text      
      tmpY = TSX_EnhancedVehicle.fuel.posY 
      setTextAlignment(RenderText.ALIGN_LEFT);    
      setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BOTTOM)
      setTextBold(false);
      if fuel_txt_diesel ~= "" then
        setTextColor(unpack(TSX_EnhancedVehicle.color.fuel))        
        renderText(TSX_EnhancedVehicle.fuel.posX, tmpY, TSX_EnhancedVehicle.fontSize, fuel_txt_diesel)
        tmpY = tmpY + (TSX_EnhancedVehicle.fontSize + TSX_EnhancedVehicle.textPadding) * 1
      end
      if fuel_txt_adblue ~= "" then
        setTextColor(unpack(TSX_EnhancedVehicle.color.adblue))        
        renderText(TSX_EnhancedVehicle.fuel.posX, tmpY, TSX_EnhancedVehicle.fontSize, fuel_txt_adblue)
        tmpY = tmpY + (TSX_EnhancedVehicle.fontSize + TSX_EnhancedVehicle.textPadding) * 1
      end
      if fuel_txt_usage ~= "" then
        setTextColor(1,1,1,1);
        renderText(TSX_EnhancedVehicle.fuel.posX, tmpY, TSX_EnhancedVehicle.fontSize, fuel_txt_usage)
      end
      setTextColor(1,1,1,1);
    end

    -- ### do the damage stuff ###
    if self.spec_wearable ~= nil and TSX_EnhancedVehicle.dmg.enabled then
      -- prepare text
      h = 0
      dmg_txt = ""
      if self.spec_wearable.totalAmount ~= nil then
        dmg_txt = string.format("%s: %.1f", self.typeDesc, (self.spec_wearable.totalAmount * 100)) .. "%"
        h = h + TSX_EnhancedVehicle.fontSize + TSX_EnhancedVehicle.textPadding 
      end

      dmg_txt2 = ""
      if self.spec_attacherJoints ~= nil then
        getDmg(self.spec_attacherJoints)
      end

      -- render overlay
      w = getTextWidth(TSX_EnhancedVehicle.fontSize, dmg_txt)
      tmp = getTextWidth(TSX_EnhancedVehicle.fontSize, dmg_txt2) + 0.005
      if tmp > w then
        w = tmp
      end
      renderOverlay(TSX_EnhancedVehicle.overlay["dmg"], TSX_EnhancedVehicle.dmg.posX - TSX_EnhancedVehicle.overlayBorder - w, TSX_EnhancedVehicle.dmg.posY - TSX_EnhancedVehicle.overlayBorder, w + (TSX_EnhancedVehicle.overlayBorder * 2), h + (TSX_EnhancedVehicle.overlayBorder * 2))

      -- render text      
      setTextColor(1,1,1,1);
      setTextAlignment(RenderText.ALIGN_RIGHT);    
      setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BOTTOM)
      setTextColor(unpack(TSX_EnhancedVehicle.color.dmg))        
      setTextBold(false);
      renderText(TSX_EnhancedVehicle.dmg.posX, TSX_EnhancedVehicle.dmg.posY, TSX_EnhancedVehicle.fontSize, dmg_txt)
      setTextColor(1,1,1,1);
      renderText(TSX_EnhancedVehicle.dmg.posX, TSX_EnhancedVehicle.dmg.posY + TSX_EnhancedVehicle.fontSize, TSX_EnhancedVehicle.fontSize + TSX_EnhancedVehicle.textPadding, dmg_txt2)
    end

    -- ### do the misc stuff ###
    if self.spec_motorized ~= nil and TSX_EnhancedVehicle.misc.enabled then
      -- prepare text
      misc_txt = string.format("%.1f", self:getTotalMass(true)) .. "t (total: " .. string.format("%.1f", self:getTotalMass()) .. " t)"          

      -- render overlay
      w = getTextWidth(TSX_EnhancedVehicle.fontSize, misc_txt)
      h = getTextHeight(TSX_EnhancedVehicle.fontSize, misc_txt) 
      renderOverlay(TSX_EnhancedVehicle.overlay["misc"], TSX_EnhancedVehicle.misc.posX - TSX_EnhancedVehicle.overlayBorder - (w/2), TSX_EnhancedVehicle.misc.posY - TSX_EnhancedVehicle.overlayBorder, w + (TSX_EnhancedVehicle.overlayBorder * 2), h + (TSX_EnhancedVehicle.overlayBorder * 2))

      -- render text      
      setTextColor(1,1,1,1);
      setTextAlignment(RenderText.ALIGN_CENTER);    
      setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BOTTOM)
      setTextBold(false);
      renderText(TSX_EnhancedVehicle.misc.posX, TSX_EnhancedVehicle.misc.posY, TSX_EnhancedVehicle.fontSize, misc_txt)
    end

    -- ### do the rpm stuff ###
    if self.spec_motorized ~= nil and TSX_EnhancedVehicle.rpm.enabled then
      -- prepare text
      rpm_txt = "--\nrpm"
      if self.spec_motorized.isMotorStarted == true then
        rpm_txt = string.format("%i\nrpm", self.spec_motorized.motor.lastMotorRpm) 
      end 

      -- render text      
      setTextColor(1,1,1,1);
      setTextAlignment(RenderText.ALIGN_CENTER);    
      setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
      setTextBold(true);
      renderText(TSX_EnhancedVehicle.rpm.posX, TSX_EnhancedVehicle.rpm.posY, TSX_EnhancedVehicle.fontSize, rpm_txt)
    end

    -- ### do the temperature stuff ###
    if self.spec_motorized ~= nil and TSX_EnhancedVehicle.temp.enabled and self.isServer then
      -- prepare text
      temp_txt = "--\n°C"
      if self.spec_motorized.isMotorStarted == true then
        temp_txt = string.format("%i\n°C", self.spec_motorized.motorTemperature.value) 
      end 

      -- render text      
      setTextColor(1,1,1,1);
      setTextAlignment(RenderText.ALIGN_CENTER);    
      setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
      setTextBold(true);
      renderText(TSX_EnhancedVehicle.temp.posX, TSX_EnhancedVehicle.temp.posY, TSX_EnhancedVehicle.fontSize, temp_txt)
    end

    -- ### do the differential stuff ###
    if self.spec_motorized ~= nil and TSX_EnhancedVehicle.diff.enabled then
      -- prepare text
      _txt = {}
      _txt.txt = { "open", "---", "open" }
      _txt.bold = { false, false, false }
      _txt.color = { "green", "white", "green" }
      if self.vData ~= nil then
        if self.vData.is[1] then
          _txt.txt[1]   = "lock"
          _txt.bold[1]  = true
          _txt.color[1] = "red"
        end
        if self.vData.is[2] then
          _txt.txt[3]   = "lock"
          _txt.bold[3]  = true
          _txt.color[3] = "red"
        end
        if self.vData.is[3] == 0 then
          _txt.txt[2]   = "2WD"
          _txt.bold[2]  = false
          _txt.color[2] = "white"
        end
        if self.vData.is[3] == 1 then
          _txt.txt[2]   = "4WD"
          _txt.bold[2]  = true
          _txt.color[2] = "yellow"
        end
        if self.vData.is[3] == 2 then
          _txt.txt[2]   = "FWD"
          _txt.bold[2]  = false
          _txt.color[2] = "white"
        end
      end

      -- render overlay
      w = getTextWidth(TSX_EnhancedVehicle.fontSize, "VL-           -VR")
      h = getTextHeight(TSX_EnhancedVehicle.fontSize, "X\nX\nX\nX\nX") 
      renderOverlay(TSX_EnhancedVehicle.overlay["diff"], TSX_EnhancedVehicle.diff.posX - TSX_EnhancedVehicle.overlayBorder - (w/2), TSX_EnhancedVehicle.diff.posY - TSX_EnhancedVehicle.overlayBorder, w + (TSX_EnhancedVehicle.overlayBorder * 2), h + (TSX_EnhancedVehicle.overlayBorder * 2))

      -- render text      
      setTextColor(1,1,1,1);
      setTextAlignment(RenderText.ALIGN_CENTER);    
      setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BOTTOM)
      setTextBold(false)
      renderText(TSX_EnhancedVehicle.diff.posX, TSX_EnhancedVehicle.diff.posY, TSX_EnhancedVehicle.fontSize, "VL-           -VR\n|\n\n|\nHL-           -HR")
      tmpY = TSX_EnhancedVehicle.diff.posY 
      for j=3, 1, -1 do
        setTextBold(_txt.bold[j])        
        setTextColor(unpack(TSX_EnhancedVehicle.color[_txt.color[j]]))        
        renderText(TSX_EnhancedVehicle.diff.posX, tmpY, TSX_EnhancedVehicle.fontSize, _txt.txt[j])
        tmpY = tmpY + (TSX_EnhancedVehicle.fontSize + TSX_EnhancedVehicle.textPadding) * 2
      end
      
    end

    -- reset text stuff to "defaults"
    setTextColor(1,1,1,1);
    setTextAlignment(RenderText.ALIGN_LEFT);
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
    setTextBold(false);
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
  self.vData.is[1] = streamReadBool(streamId);  
  self.vData.is[2] = streamReadBool(streamId);  
  self.vData.is[3] = streamReadInt32(streamId);

  if self.isClient then
    self.vData.want[1] = self.vData.is[1]  
    self.vData.want[2] = self.vData.is[2]  
    self.vData.want[3] = self.vData.is[3]
  end  

--  if debug then print(DebugUtil.printTableRecursively(self.vData, 0, 0, 2)) end
end

-- #############################################################################

function TSX_EnhancedVehicle:onWriteStream(streamId, connection)
  if debug > 1 then print("-> " .. myName .. ": onWriteStream - " .. streamId .. mySelf(self)) end

  -- send initial data to client
  if g_dedicatedServerInfo ~= nil then
    -- when dedicated server then send want array to client cause onUpdate never ran and thus vData "is" is "wrong"
    streamWriteBool(streamId,  self.vData.want[1])
    streamWriteBool(streamId,  self.vData.want[2])
    streamWriteInt32(streamId, self.vData.want[3])
  else
    streamWriteBool(streamId,  self.vData.is[1])
    streamWriteBool(streamId,  self.vData.is[2])
    streamWriteInt32(streamId, self.vData.is[3])
  end
end

-- #############################################################################

function TSX_EnhancedVehicle:onRegisterActionEvents(isSelected, isOnActiveVehicle)
  if debug > 1 then print("-> " .. myName .. ": onRegisterActionEvents " .. bool_to_number(isSelected) .. ", " .. bool_to_number(isOnActiveVehicle) .. ", S: " .. bool_to_number(self.isServer) .. ", C: " .. bool_to_number(self.isClient) .. mySelf(self)) end

  -- continue on client side only
  if not self.isClient then
    return
  end
  
  -- only in active vehicle
  if isOnActiveVehicle then
    -- we could have more than one event, so prepare a table to store them  
    if self.ActionEvents == nil then 
      self.ActionEvents = {}
    else  
      self:clearActionEventsTable( self.ActionEvents )
    end 
    
    -- attach our actions
    for _ ,actionName in pairs(TSX_EnhancedVehicle.actions) do
      local _, eventName = self:addActionEvent(self.ActionEvents, InputAction[actionName], self, TSX_EnhancedVehicle.onActionCall, false, true, false, true, nil);

      -- help menu priorization
      if g_inputBinding ~= nil and g_inputBinding.events ~= nil and g_inputBinding.events[eventName] ~= nil then
        if isSelected then
          -- highest priority in help menu
          g_inputBinding.events[eventName].displayPriority = 1
        elseif isOnActiveVehicle then
          -- lowest priority in help menu
          g_inputBinding.events[eventName].displayPriority = 3
          if actionName == "TSX_EnhancedVehicle_RESET" then
            g_inputBinding.events[eventName].displayPriority = 99
          end
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
    self.vData.want[1] = not self.vData.want[1]
    if self.isClient and not self.isServer then
      self.vData.is[1] = self.vData.want[1]
    end        
    TSX_EnhancedVehicle_Event:sendEvent(self, self.vData.want[1], self.vData.want[2], self.vData.want[3]);
  end

  -- back diff
  if actionName == "TSX_EnhancedVehicle_RD" then
    self.vData.want[2] = not self.vData.want[2]
    if self.isClient and not self.isServer then
      self.vData.is[2] = self.vData.want[2]
    end        
    TSX_EnhancedVehicle_Event:sendEvent(self, self.vData.want[1], self.vData.want[2], self.vData.want[3]);
  end

  -- wheel drive mode
  if actionName == "TSX_EnhancedVehicle_DM" then
    self.vData.want[3] = self.vData.want[3] + 1
    if self.vData.want[3] > 1 then
      self.vData.want[3] = 0
    end
    if self.isClient and not self.isServer then
      self.vData.is[3] = self.vData.want[3]
    end        
    TSX_EnhancedVehicle_Event:sendEvent(self, self.vData.want[1], self.vData.want[2], self.vData.want[3]);
  end

  -- reset config
  if actionName == "TSX_EnhancedVehicle_RESET" then
    for _, section in ipairs(TSX_EnhancedVehicle.sections) do
      TSX_EnhancedVehicle[section] = nil
    end
    TSX_EnhancedVehicle:resetConfig()
  end
end

-- #############################################################################

function bool_to_number(value)
  return value and 1 or 0
end

function getDmg(start)
  if start.spec_attacherJoints.attachedImplements ~= nil then      
    for _, implement in pairs(start.spec_attacherJoints.attachedImplements) do
      dmg_txt2 = string.format("%s: %.1f", implement.object.typeDesc, (implement.object.spec_wearable.totalAmount * 100)) .. "%\n" .. dmg_txt2
      h = h + TSX_EnhancedVehicle.fontSize + TSX_EnhancedVehicle.textPadding 
      if implement.object.spec_attacherJoints ~= nil then
        getDmg(implement.object)
      end
    end
  end
end

function mySelf(obj)
  return " (rootNode: " .. obj.rootNode .. ", typeName: " .. obj.typeName .. ", typeDesc: " .. obj.typeDesc .. ")"
end
