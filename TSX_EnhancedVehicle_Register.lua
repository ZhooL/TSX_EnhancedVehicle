--
-- Mod: TSX_EnhancedVehicle_Register
--
-- Author: ZhooL
-- email: ls19@dark-world.de
-- @Date: 01.01.2019
-- @Version: 1.3.1.0 

-- #############################################################################

source(Utils.getFilename("TSX_EnhancedVehicle.lua", g_currentModDirectory))
source(Utils.getFilename("TSX_EnhancedVehicle_Event.lua", g_currentModDirectory))

TSX_EnhancedVehicle_Register = {}
TSX_EnhancedVehicle_Register.modDirectory = g_currentModDirectory;

local modDesc = loadXMLFile("modDesc", g_currentModDirectory .. "modDesc.xml");
TSX_EnhancedVehicle_Register.version = getXMLString(modDesc, "modDesc.version");

if g_specializationManager:getSpecializationByName("TSX_EnhancedVehicle") == nil then
  if TSX_EnhancedVehicle == nil then 
    print("ERROR: unable to add specialization 'TSX_EnhancedVehicle'")
  else 
    for i, typeDef in pairs(g_vehicleTypeManager.vehicleTypes) do
      if typeDef ~= nil and i ~= "locomotive" then 
        local isDrivable  = false
        local isEnterable = false
        local hasMotor    = false 
        for name, spec in pairs(typeDef.specializationsByName) do
          if name == "drivable"  then 
            isDrivable = true 
          elseif name == "motorized" then 
            hasMotor = true 
          elseif name == "enterable" then 
            isEnterable = true 
          end 
        end 
        if isDrivable and isEnterable and hasMotor then 
          if debug > 1 then print("INFO: attached specialization 'TSX_EnhancedVehicle' to vehicleType '" .. tostring(i) .. "'") end
          typeDef.specializationsByName["TSX_EnhancedVehicle"] = TSX_EnhancedVehicle
          table.insert(typeDef.specializationNames, "TSX_EnhancedVehicle")
          table.insert(typeDef.specializations, TSX_EnhancedVehicle)  
        end 
      end 
    end   
  end 
end 

-- #############################################################################

function TSX_EnhancedVehicle_Register:loadMap()
  print("--> loaded TSX_EnhancedVehicle version " .. self.version .. " (by ZhooL) <--");
end

-- #############################################################################

function TSX_EnhancedVehicle_Register:deleteMap()
  print("--> unloaded TSX_EnhancedVehicle version " .. self.version .. " (by ZhooL) <--");
end

-- #############################################################################

function TSX_EnhancedVehicle_Register:keyEvent(unicode, sym, modifier, isDown)
  if Input.isKeyPressed(Input.KEY_KP_7) then
    TSX_EnhancedVehicle.keyPressed.diff_front = true
--    if debug then print("KEY_KP_7 pressed") end
  end
  if Input.isKeyPressed(Input.KEY_KP_8) then
    TSX_EnhancedVehicle.keyPressed.diff_back = true
--    if debug then print("KEY_KP_8 pressed") end
  end
  if Input.isKeyPressed(Input.KEY_KP_9) then
    TSX_EnhancedVehicle.keyPressed.wd_mode = true
--    if debug then print("KEY_KP_9 pressed") end
  end
end

-- #############################################################################

function TSX_EnhancedVehicle_Register:mouseEvent(posX, posY, isDown, isUp, button)
end

-- #############################################################################

function TSX_EnhancedVehicle_Register:update(dt)
end

-- #############################################################################

addModEventListener(TSX_EnhancedVehicle_Register);
