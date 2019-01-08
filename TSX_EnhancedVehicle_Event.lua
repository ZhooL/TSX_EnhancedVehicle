--
-- Mod: TSX_EnhancedVehicle_Event
--
-- Author: ZhooL
-- email: ls19@dark-world.de
-- @Date: 08.01.2019
-- @Version: 1.5.0.0

local myName = "TSX_EnhancedVehicle_Event"

-- #############################################################################

TSX_EnhancedVehicle_Event = {}
TSX_EnhancedVehicle_Event_mt = Class(TSX_EnhancedVehicle_Event, Event)
InitEventClass(TSX_EnhancedVehicle_Event, "TSX_EnhancedVehicle_Event")

-- #############################################################################

function TSX_EnhancedVehicle_Event:emptyNew()
  if debug > 2 then print("-> " .. myName .. ": emptyNew()") end

  local self = Event:new(TSX_EnhancedVehicle_Event_mt)
  self.className = "TSX_EnhancedVehicle_Event"
  return self
end

-- #############################################################################

function TSX_EnhancedVehicle_Event:new(vehicle, ...)
  local args = { ... }
  if debug > 1 then print("-> " .. myName .. ": new(): " .. lU:args_to_txt(unpack(args))) end

  local self = TSX_EnhancedVehicle_Event:emptyNew()
  self.vehicle = vehicle
  self.vehicle.vData.want = { unpack(args) }

  return self
end

-- #############################################################################

function TSX_EnhancedVehicle_Event:readStream(streamId, connection)
  if debug > 1 then print("-> " .. myName .. ": readStream() - " .. streamId) end

  self.vehicle               = NetworkUtil.readNodeObject(streamId);
  self.vehicle.vData.want[1] = streamReadBool(streamId);
  self.vehicle.vData.want[2] = streamReadBool(streamId);
  self.vehicle.vData.want[3] = streamReadInt8(streamId);
  self.vehicle.vData.want[4] = streamReadBool(streamId);
  self.vehicle.vData.want[5] = streamReadBool(streamId);

  if not connection:getIsServer() then
    g_server:broadcastEvent(TSX_EnhancedVehicle_Event:new(self.vehicle, unpack(self.vehicle.vData.want)), nil, connection)
  end

  if g_server == nil then
    self.vehicle.vData.is = { unpack(self.vehicle.vData.want) }
  end

  if debug > 1 then print("--> " .. self.vehicle.rootNode .. " - (" .. lU:args_to_txt(unpack(self.vehicle.vData.is)).."|"..lU:args_to_txt(unpack(self.vehicle.vData.want))..")") end
--  print(DebugUtil.printTableRecursively(self.vehicle.vData, 0, 0, 2))
end

-- #############################################################################

function TSX_EnhancedVehicle_Event:writeStream(streamId, connection)
  if debug > 1 then print("-> " .. myName .. ": writeStream() - " .. streamId) end

  NetworkUtil.writeNodeObject(streamId, self.vehicle);
  streamWriteBool(streamId, self.vehicle.vData.want[1])
  streamWriteBool(streamId, self.vehicle.vData.want[2])
  streamWriteInt8(streamId, self.vehicle.vData.want[3])
  streamWriteBool(streamId, self.vehicle.vData.want[4])
  streamWriteBool(streamId, self.vehicle.vData.want[5])
end

-- #############################################################################

function TSX_EnhancedVehicle_Event:sendEvent(vehicle, ...)
  local args = { ... }
  if debug > 1 then print("-> " .. myName .. ": sendEvent(): " .. lU:args_to_txt(unpack(args))) end

  if g_server ~= nil then
    if debug > 2 then print("--> g_server:broadcastEvent()") end
    g_server:broadcastEvent(TSX_EnhancedVehicle_Event:new(vehicle, unpack(args)), nil, nil, vehicle)
  else
    if debug > 2 then print("--> g_client:getServerConnection():sendEvent()") end
    g_client:getServerConnection():sendEvent(TSX_EnhancedVehicle_Event:new(vehicle, unpack(args)))
  end
end
