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
-- Copyright 2023 SmartThings
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

-- Modified from v1-contact-event for use with Ring Retrofit Alarm Kit

local cc = require "st.zwave.CommandClass"
local Notification = (require "st.zwave.CommandClass.Notification")({ version = 8 })
local capabilities = require "st.capabilities"

local function can_handle_ring_contact_event(opts, driver, device, cmd, ...)
  return 
    opts.dispatcher_class == "ZwaveDispatcher" and
    cmd ~= nil and
    cmd.cmd_class ~= nil and
    cmd.cmd_class == cc.NOTIFICATION and
    cmd.cmd_id == Notification.REPORT and
    cmd.args.notification_type == Notification.notification_type.HOME_SECURITY and 
	( cmd.args.event == Notification.event.home_security.TAMPERING_PRODUCT_COVER_REMOVED or
	  cmd.args.event == Notification.event.home_monitoring.STATE_IDLE or
	  cmd.args.event == Notification.event.home_monitoring.INTRUSION_LOCATION_PROVIDED
	)
end

local function handle_ring_contact_event(driver, device, cmd)
  if cmd.args.event == Notification.event.home_monitoring.STATE_IDLE then
    device:emit_event_for_endpoint(cmd.src_channel, capabilities.contactSensor.contact.closed())
  else
    if cmd.args.event == Notification.event.home_security.TAMPERING_PRODUCT_COVER_REMOVED or 
         cmd.args.event == Notification.event.home_monitoring.INTRUSION_LOCATION_PROVIDED then
      device:emit_event_for_endpoint(cmd.src_channel, capabilities.contactSensor.contact.open())
    end
  end
end

local ring_retrofit_kit_contact_event = {
  zwave_handlers = {
    [cc.NOTIFICATION] = {
      [Notification.REPORT] = handle_ring_contact_event
    }
  },
  NAME = "ring_retrofit_kit_contact_event",
  can_handle = can_handle_ring_contact_event
}

return ring_retrofit_kit_contact_event
