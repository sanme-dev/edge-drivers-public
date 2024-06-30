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


local capabilities = require "st.capabilities"
local defaults = require "st.zwave.defaults"
local st_device = require "st.device"
local ZwaveDriver = require "st.zwave.driver"
local cc = require "st.zwave.CommandClass"

local Basic = (require "st.zwave.CommandClass.Basic")({ version = 2 })
local WakeUp = (require "st.zwave.CommandClass.WakeUp")({ version = 2 })

local configurations = require "configurations"
--local log = require('log')


local function component_to_endpoint(device, component_id)
  local ep_num = component_id:match("contact(%d)")
  return { ep_num and tonumber(ep_num) }
end


local function endpoint_to_component(device, ep)
  local contact_comp = string.format("contact%d", ep)
  if device.profile.components[contact_comp] ~= nil then
    return contact_comp
  else
    return "main"
  end
end


local device_init = function(self, device)
  device:set_component_to_endpoint_fn(component_to_endpoint)
  device:set_endpoint_to_component_fn(endpoint_to_component)
end


local function read_states(device)
  local basic_get = Basic:Get({ })
  
  -- TODO: Could enhance the report handler so that it only emits events if the value is changed
  --       and then this could be used for querying status on wake up (in case any messages were
  --       missed somehow) vs only being used for setting initial state.  Also would handle the
  --       case where the hub was rebooted to at least get all current values on wakeup.  That
  --       said, the default wakeup interval is long and making it shorter will reduce battery life.
  --       Maybe it's best to still think of these contacts as only being useful on edge trigger,
  --       though that means device users will not get triggers for state changes that got lost
  --       (ex: hub offline) and there is no catch-up logic.
  
  -- TODO: If we are treating them as only edge triggered per the above comment, do we even want
  --       the initial values to populate in to the device when it is first included?
  
  -- The device docs only indicate Basic:Get can be used with each of the eight contact endpoints.
  -- In addition, if we do query the "main" component it seems to always report as closed even if
  -- it is open.  Possible some future firmware might support querying this.
  --   device:send_to_component(basic_get, "main")
  device:emit_event_for_endpoint(0, capabilities.contactSensor.contact.closed())
  
  -- Read current contact values
  device:send_to_component(basic_get, "contact1")
  device:send_to_component(basic_get, "contact2")
  device:send_to_component(basic_get, "contact3")
  device:send_to_component(basic_get, "contact4")
  device:send_to_component(basic_get, "contact5")
  device:send_to_component(basic_get, "contact6")
  device:send_to_component(basic_get, "contact7")
  device:send_to_component(basic_get, "contact8")
end


-- TODO: Eventually add configuraiton and the ability for it to update on wakeup.  this
--       code is simply retained from SmartThings edge drivers this borrowed from.
local function info_changed(driver, device, event, args)
end


-- TODO: Eventually add configuraiton and the ability for it to update on wakeup.  this
--       code is simply retained from SmartThings edge drivers this borrowed from.
local function wakeup_notification(driver, device, cmd)
  --Note sending WakeUpIntervalGet the first time a device wakes up will happen by default in Lua libs 0.49.x and higher
  --This is done to help the hub correctly set the checkInterval for migrated devices.
  if not device:get_field("__wakeup_interval_get_sent") then
    device:send(WakeUp:IntervalGetV1({}))
    device:set_field("__wakeup_interval_get_sent", true)
  end
  device:refresh()
end


local function do_configure(driver, device)
  configurations.initial_configuration(driver, device)
  read_states(device)
  device:refresh()
end


local function device_added(driver, device)
  device:refresh()
end


-------------------------------------------------------------------------------------------
-- Register message handlers and run driver
-------------------------------------------------------------------------------------------
local driver_template = {
  supported_capabilities = {
    capabilities.battery,
    capabilities.contactSensor
  },
  zwave_handlers = {
    [cc.WAKE_UP] = {
      [WakeUp.NOTIFICATION] = wakeup_notification
    }
  },
  sub_drivers = {
    require("ring-retrofit-contact-event")
  },
  lifecycle_handlers = {
    init = device_init,
    infoChanged = info_changed,
    doConfigure = do_configure,
    added = device_added
  }
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)

local ring_retrofit_kit = ZwaveDriver("ring_retrofit_kit", driver_template)
ring_retrofit_kit:run()
