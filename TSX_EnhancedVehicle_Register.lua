--
-- Mod: TSX_EnhancedVehicle_Register
--
-- Author: ZhooL
-- email: ls19@dark-world.de
-- @Date: 20.01.2019
-- @Version: 1.6.3.0

-- #############################################################################

source(Utils.getFilename("TSX_EnhancedVehicle.lua", g_currentModDirectory))
source(Utils.getFilename("TSX_EnhancedVehicle_Event.lua", g_currentModDirectory))

-- include our libUtils
source(Utils.getFilename("libUtils.lua", g_currentModDirectory))
lU = libUtils()
lU:setDebug(0)

-- include our new libConfig XML management
source(Utils.getFilename("libConfig.lua", g_currentModDirectory))
lC = libConfig("TSX_EnhancedVehicle", 1, 0)
lC:setDebug(0)

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

  -- first set our current and default config to default values
  if g_modIsLoaded.FS19_KeyboardSteer ~= nil or g_modIsLoaded.FS19_VehicleControlAddon ~= nil then
    TSX_EnhancedVehicle:resetConfig(true)
  else
    TSX_EnhancedVehicle:resetConfig()
  end

  -- then read values from disk and "overwrite" current config
  lC:readConfig()
  -- then write current config (which is now a merge between default values and from disk)
  lC:writeConfig()
  -- and finally activate current config
  TSX_EnhancedVehicle:activateConfig()
end

-- #############################################################################

function TSX_EnhancedVehicle_Register:deleteMap()
  print("--> unloaded TSX_EnhancedVehicle version " .. self.version .. " (by ZhooL) <--");
end

-- #############################################################################

function TSX_EnhancedVehicle_Register:keyEvent(unicode, sym, modifier, isDown)
end

-- #############################################################################

function TSX_EnhancedVehicle_Register:mouseEvent(posX, posY, isDown, isUp, button)
end

-- #############################################################################

function TSX_EnhancedVehicle_Register:update(dt)
end

-- #############################################################################

addModEventListener(TSX_EnhancedVehicle_Register);
