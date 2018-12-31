--
-- Mod: TSX_EnhancedVehicle_Event
--
-- Author: ZhooL
-- email: ls19@dark-world.de
-- @Date: 31.12.2018
-- @Version: 1.3.0.0 

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

function TSX_EnhancedVehicle_Event:new(vehicle, diff_front, diff_back, wd_mode)
  if debug > 2 then print("-> " .. myName .. ": new() - " .. bool_to_number(diff_front) .. "/" .. bool_to_number(diff_back) .. "/" .. wd_mode) end

  local self = TSX_EnhancedVehicle_Event:emptyNew()
  self.vehicle    = vehicle
  self.vehicle.vData.want[1] = diff_front
  self.vehicle.vData.want[2] = diff_back
  self.vehicle.vData.want[3] = wd_mode
 
  return self
end

-- #############################################################################

function TSX_EnhancedVehicle_Event:readStream(streamId, connection)
  if debug > 1 then print("-> " .. myName .. ": readStream() - " .. streamId) end
  
  self.vehicle               = NetworkUtil.readNodeObject(streamId);
  self.vehicle.vData.want[1] = streamReadBool(streamId);  
  self.vehicle.vData.want[2] = streamReadBool(streamId);  
  self.vehicle.vData.want[3] = streamReadInt32(streamId);

  if not connection:getIsServer() then
    g_server:broadcastEvent(TSX_EnhancedVehicle_Event:new(self.vehicle, self.vehicle.vData.want[1], self.vehicle.vData.want[2], self.vehicle.vData.want[3]), nil, connection)
  end

  if g_server == nil then
    self.vehicle.vData.is[1] = self.vehicle.vData.want[1]
    self.vehicle.vData.is[2] = self.vehicle.vData.want[2]
    self.vehicle.vData.is[3] = self.vehicle.vData.want[3]
  end
      
  if debug > 1 then print("--> " .. self.vehicle.rootNode .. "/(" .. bool_to_number(self.vehicle.vData.is[1]).."|"..bool_to_number(self.vehicle.vData.want[1]) .. ")/(" .. bool_to_number(self.vehicle.vData.is[2]).."|"..bool_to_number(self.vehicle.vData.want[2]) .. ")/(" .. bool_to_number(self.vehicle.vData.is[3]).."|"..self.vehicle.vData.want[3]..")") end
--  print(DebugUtil.printTableRecursively(self.vehicle.vData, 0, 0, 2))
end

-- #############################################################################

function TSX_EnhancedVehicle_Event:writeStream(streamId, connection)
  if debug > 1 then print("-> " .. myName .. ": writeStream() - " .. streamId) end

  NetworkUtil.writeNodeObject(streamId, self.vehicle);
  streamWriteBool(streamId, self.vehicle.vData.want[1])
  streamWriteBool(streamId, self.vehicle.vData.want[2])
  streamWriteInt32(streamId, self.vehicle.vData.want[3])
end

-- #############################################################################

function TSX_EnhancedVehicle_Event:sendEvent(vehicle, diff_front, diff_back, wd_mode)
  if debug > 1 then print("-> " .. myName .. ": sendEvent() - " .. vehicle.rootNode .. "/" .. bool_to_number(diff_front) .. "/" .. bool_to_number(diff_back) .. "/" .. wd_mode) end

  if g_server ~= nil then
    if debug > 2 then print("--> g_server:broadcastEvent()") end
    g_server:broadcastEvent(TSX_EnhancedVehicle_Event:new(vehicle, diff_front, diff_back, wd_mode), nil, nil, vehicle)
  else
    if debug > 2 then print("--> g_client:getServerConnection():sendEvent()") end
    g_client:getServerConnection():sendEvent(TSX_EnhancedVehicle_Event:new(vehicle, diff_front, diff_back, wd_mode))
  end
end
