-- Copyright 2024 Michael Sanzo
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

-- Based upon source code from SmartThingsEdgeDrivers project:
--
-- https://github.com/SmartThingsCommunity/SmartThingsEdgeDrivers

-- Original copyright:
--
-- Copyright 2022 SmartThings
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- Modified for use with Ring Retrofit Alarm Kit


local Association = (require "st.zwave.CommandClass.Association")({ version=2 })
local Notification = (require "st.zwave.CommandClass.Notification")({ version=8 })
local st_device = require "st.device"

--local log = require('log')

local devices = {
  RING_RETROFIT_KIT = {
    MATCHING_MATRIX = {
      mfrs = 0x0346,
      product_types = 0x0B01,
      product_ids = 0x0101
    }
  }
}

local configurations = {}

configurations.initial_configuration = function(driver, device)
 if configurations.device_matched(device) then
	  
    local hub_id = driver.environment_info.hub_zwave_id
    local _node_ids = { hub_id }
 
    -- TODO: Is this really necessary?
	--   Remove SmartThings default lifeline assocation and re-associate using multi-channel encapsulation
	device:send(Association:Remove({grouping_identifier = 1, node_ids = _node_ids}))
	device:send_to_component(Association:Set({grouping_identifier = 1, node_ids = _node_ids}), "main")
	
	-- Multi-channel encapsulated association to each of the contact endpoints so that reports are received
	device:send_to_component(Association:Set({grouping_identifier = 2, node_ids = _node_ids}), "contact1")
	device:send_to_component(Association:Set({grouping_identifier = 2, node_ids = _node_ids}), "contact2")
	device:send_to_component(Association:Set({grouping_identifier = 2, node_ids = _node_ids}), "contact3")
	device:send_to_component(Association:Set({grouping_identifier = 2, node_ids = _node_ids}), "contact4")
	device:send_to_component(Association:Set({grouping_identifier = 2, node_ids = _node_ids}), "contact5")
	device:send_to_component(Association:Set({grouping_identifier = 2, node_ids = _node_ids}), "contact6")
	device:send_to_component(Association:Set({grouping_identifier = 2, node_ids = _node_ids}), "contact7")
	device:send_to_component(Association:Set({grouping_identifier = 2, node_ids = _node_ids}), "contact8")

    -- Enable home secuity notification reports
	device:send(Notification:Set({notification_type = Notification.notification_type.HOME_SECURITY, notification_status = Notification.notification_status.ON}))
  end
end

configurations.device_matched = function(zw_device)
  for _, device in pairs(devices) do
    if zw_device:id_match(
      device.MATCHING_MATRIX.mfrs,
      device.MATCHING_MATRIX.product_types,
      device.MATCHING_MATRIX.product_ids) then
      return true
    end
  end
  return false
end

return configurations
