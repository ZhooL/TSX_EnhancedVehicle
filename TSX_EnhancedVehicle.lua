--
-- Mod: TSX_EnhancedVehicle
--
-- Author: ZhooL
-- email: ls19@dark-world.de
-- @Date: 31.12.2018
-- @Version: 1.3.0.0 

debug = 0 -- 0=0ff, 1=some, 2=everything, 3=madness
local myName = "TSX_EnhancedVehicle"

-- #############################################################################

TSX_EnhancedVehicle = {}
TSX_EnhancedVehicle.modDirectory = g_currentModDirectory;

-- some global stuff
TSX_EnhancedVehicle.fontSize    = 0.01 
TSX_EnhancedVehicle.textPadding = 0.001

-- for HUD damage enhancement
TSX_EnhancedVehicle.dmg = {}
TSX_EnhancedVehicle.dmg.posX = 0
TSX_EnhancedVehicle.dmg.posY = 0

-- for HUD fuel enhancement
TSX_EnhancedVehicle.fuel = {}
TSX_EnhancedVehicle.fuel.posX = 0
TSX_EnhancedVehicle.fuel.posY = 0

-- for HUD misc enhancement
TSX_EnhancedVehicle.misc = {}
TSX_EnhancedVehicle.misc.posX = 0
TSX_EnhancedVehicle.misc.posY = 0

-- for HUD differential display
TSX_EnhancedVehicle.diff = {}
TSX_EnhancedVehicle.diff.posX = 0
TSX_EnhancedVehicle.diff.posY = 0

-- for vehicle status and data information
TSX_EnhancedVehicle.vData = {}

-- for tracking key press
TSX_EnhancedVehicle.keyPressed = {}
TSX_EnhancedVehicle.keyPressed.diff_front = false
TSX_EnhancedVehicle.keyPressed.diff_back  = false
TSX_EnhancedVehicle.keyPressed.wd_mode    = false

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

end

-- #############################################################################

function TSX_EnhancedVehicle:onUpdate(dt)
  if debug > 2 then print("-> " .. myName .. ": onUpdate " .. dt .. ", S: " .. bool_to_number(self.isServer) .. ", C: " .. bool_to_number(self.isClient) .. mySelf(self)) end

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
      if debug > 0 then print("setup of differentials done" .. mySelf(self)) end            
    end
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

  -- handle key press event on client site only wenn inside a human controlled vehicle 
  if not self:getIsAIActive() and self:getIsActive() and self.isClient and self.getIsControlled and g_gameSettings.nickname == self:getControllerName() then
    -- front diff
    if TSX_EnhancedVehicle.keyPressed.diff_front then
      self.vData.want[1] = not self.vData.want[1]
      if self.isClient and not self.isServer then
        self.vData.is[1] = self.vData.want[1]
      end        
      TSX_EnhancedVehicle_Event:sendEvent(self, self.vData.want[1], self.vData.want[2], self.vData.want[3]);
      TSX_EnhancedVehicle.keyPressed.diff_front = false -- reset key press    
    end
    -- back diff
    if TSX_EnhancedVehicle.keyPressed.diff_back then
      self.vData.want[2] = not self.vData.want[2]
      if self.isClient and not self.isServer then
        self.vData.is[2] = self.vData.want[2]
      end        
      TSX_EnhancedVehicle_Event:sendEvent(self, self.vData.want[1], self.vData.want[2], self.vData.want[3]);
      TSX_EnhancedVehicle.keyPressed.diff_back = false -- reset key press    
    end
    -- wheel drive mode
    if TSX_EnhancedVehicle.keyPressed.wd_mode then
      self.vData.want[3] = self.vData.want[3] + 1
      if self.vData.want[3] > 1 then
        self.vData.want[3] = 0
      end
      if self.isClient and not self.isServer then
        self.vData.is[3] = self.vData.want[3]
      end        
      TSX_EnhancedVehicle_Event:sendEvent(self, self.vData.want[1], self.vData.want[2], self.vData.want[3]);
      TSX_EnhancedVehicle.keyPressed.wd_mode = false -- reset key press    
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

    -- ### do the fuel stuff ###
    if self.spec_fillUnit ~= nil then
      -- get coordinates
      if g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeIconElement ~= nil then
        TSX_EnhancedVehicle.fuel.posX = g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeIconElement.overlay.x
        TSX_EnhancedVehicle.fuel.posY = g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeIconElement.overlay.y + g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeIconElement.overlay.height
      end
      
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
      fuel_txt_usage = ""
      fuel_txt_diesel = ""
      fuel_txt_adblue = ""
      if fuel_diesel_current >= 0 then
        fuel_txt_diesel = string.format("%.1f l/%.1f l", fuel_diesel_current, fuel_diesel_max)
      end
      if fuel_adblue_current >= 0 then
        fuel_txt_adblue = string.format("%.1f l/%.1f l", fuel_adblue_current, fuel_adblue_max)
      end
      if self.spec_motorized.isMotorStarted == true then
        fuel_txt_usage = string.format("%.2f l/h", self.spec_motorized.lastFuelUsage)
      end 

      -- render text      
      tmpY = TSX_EnhancedVehicle.fuel.posY 
      setTextAlignment(RenderText.ALIGN_LEFT);    
      setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BOTTOM)
      setTextBold(false);
      if fuel_txt_diesel ~= "" then
        setTextColor(unpack(getColor("fuel")))        
        renderText(TSX_EnhancedVehicle.fuel.posX, tmpY, TSX_EnhancedVehicle.fontSize, fuel_txt_diesel)
        tmpY = tmpY + (TSX_EnhancedVehicle.fontSize + TSX_EnhancedVehicle.textPadding) * 1
      end
      if fuel_txt_adblue ~= "" then
        setTextColor(unpack(getColor("blue")))        
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
    if self.spec_wearable ~= nil then
      -- get coordinates
      if g_currentMission.inGameMenu.hud.speedMeter.damageGaugeIconElement ~= nil then
        TSX_EnhancedVehicle.dmg.posX = g_currentMission.inGameMenu.hud.speedMeter.damageGaugeIconElement.overlay.x + g_currentMission.inGameMenu.hud.speedMeter.damageGaugeIconElement.overlay.width
        TSX_EnhancedVehicle.dmg.posY = g_currentMission.inGameMenu.hud.speedMeter.damageGaugeIconElement.overlay.y + g_currentMission.inGameMenu.hud.speedMeter.damageGaugeIconElement.overlay.height
      end

      -- prepare text
      dmg_txt = ""
      if self.spec_wearable.totalAmount ~= nil then
        dmg_txt = string.format("(%s) %.1f", self.typeDesc, (self.spec_wearable.totalAmount * 100)) .. "%"
      end

      dmg_txt2 = ""
      if self.spec_attacherJoints ~= nil then
        getDmg(self.spec_attacherJoints)
      end

      -- render text      
      setTextColor(1,1,1,1);
      setTextAlignment(RenderText.ALIGN_RIGHT);    
      setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BOTTOM)
      setTextColor(unpack(getColor("dmg")))        
      setTextBold(false);
      renderText(TSX_EnhancedVehicle.dmg.posX, TSX_EnhancedVehicle.dmg.posY, TSX_EnhancedVehicle.fontSize, dmg_txt)
      setTextColor(1,1,1,1);
      renderText(TSX_EnhancedVehicle.dmg.posX, TSX_EnhancedVehicle.dmg.posY + TSX_EnhancedVehicle.fontSize, TSX_EnhancedVehicle.fontSize + TSX_EnhancedVehicle.textPadding, dmg_txt2)
    end

    -- ### do the misc stuff ###
    if self.spec_motorized ~= nil then
      -- get coordinates
      if g_currentMission.inGameMenu.hud.speedMeter.operatingTimeElement ~= nil then
        TSX_EnhancedVehicle.misc.posX = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX
        TSX_EnhancedVehicle.misc.posY = g_currentMission.inGameMenu.hud.speedMeter.operatingTimeElement.overlay.y
      end

      -- prepare text
      mass_txt = string.format("%.1f", self:getTotalMass(true)) .. "t (total: " .. string.format("%.1f", self:getTotalMass()) .. " t)"          
      if self.spec_motorized.isMotorStarted == true then
        lmr = self.spec_motorized.motor.lastMotorRpm
        lmt = self.spec_motorized.motorTemperature.value
      else
        lmr = 0
        lmt = self.spec_motorized.motorTemperature.valueMin
      end 
      misc_txt = string.format("%i rpm / %.2f °C\n%s", lmr, lmt, mass_txt) 

      -- render text      
      setTextColor(1,1,1,1);
      setTextAlignment(RenderText.ALIGN_CENTER);    
      setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_TOP)
      setTextBold(false);
      renderText(TSX_EnhancedVehicle.misc.posX, TSX_EnhancedVehicle.misc.posY, TSX_EnhancedVehicle.fontSize, misc_txt)
    end

    -- ### do the differential stuff ###
    if self.spec_motorized ~= nil then
      -- get coordinates
      if g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeIconElement ~= nil then
        TSX_EnhancedVehicle.diff.posX = g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeIconElement.overlay.x + g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeIconElement.overlay.width
        TSX_EnhancedVehicle.diff.posY = g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeIconElement.overlay.y + g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeIconElement.overlay.height + ((TSX_EnhancedVehicle.fontSize + TSX_EnhancedVehicle.textPadding) * 4)
      end

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

      -- render text      
      setTextColor(1,1,1,1);
      setTextAlignment(RenderText.ALIGN_CENTER);    
      setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BOTTOM)
      setTextBold(false)
      renderText(TSX_EnhancedVehicle.diff.posX, TSX_EnhancedVehicle.diff.posY, TSX_EnhancedVehicle.fontSize, "VL-           -VR\n|\n\n|\nHL-           -HR")
      tmpY = TSX_EnhancedVehicle.diff.posY 
      for j=3, 1, -1 do
        setTextBold(_txt.bold[j])        
        setTextColor(unpack(getColor(_txt.color[j])))        
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
  streamWriteBool(streamId,  self.vData.is[1])
  streamWriteBool(streamId,  self.vData.is[2])
  streamWriteInt32(streamId, self.vData.is[3])
end

-- #############################################################################

function TSX_EnhancedVehicle:onRegisterActionEvents(isSelected, isOnActiveVehicle)
  if debug > 1 then print("-> " .. myName .. ": onRegisterActionEvents " .. bool_to_number(isSelected) .. ", " .. bool_to_number(isOnActiveVehicle) .. ", S: " .. bool_to_number(self.isServer) .. ", C: " .. bool_to_number(self.isClient) .. mySelf(self)) end
   
end

-- #############################################################################

function bool_to_number(value)
  return value and 1 or 0
end

function getColor(color)
  if color == "red" then
    return({ 255/255, 0/255, 0/255, 1 })
  end
  if color == "green" then
    return({ 0/255, 255/255, 0/255, 1 })
  end
  if color == "blue" then
    return({ 0/255, 0/255, 255/255, 1 })
  end
  if color == "yellow" then
    return({ 255/255, 255/255, 0/255, 1 })
  end
  if color == "dmg" then
    return({ 86/255, 142/255, 42/255, 1 })
  end
  if color == "fuel" then
    return({ 124/255, 90/255, 8/255, 1 })
  end
  if color == "adblue" then
    return({ 48/255, 78/255, 149/255, 1 })
  end
  return({ 1, 1, 1, 1 })
end

function getDmg(start)
  if start.spec_attacherJoints.attachedImplements ~= nil then      
    for _, implement in pairs(start.spec_attacherJoints.attachedImplements) do
      dmg_txt2 = string.format("(%s) %.1f", implement.object.typeDesc, (implement.object.spec_wearable.totalAmount * 100)) .. "%\n" .. dmg_txt2
      if implement.object.spec_attacherJoints ~= nil then
        getDmg(implement.object)
      end
    end
  end
end

function mySelf(obj)
  return " (rootNode: " .. obj.rootNode .. ", typeName: " .. obj.typeName .. ", typeDesc: " .. obj.typeDesc .. ")"
end
