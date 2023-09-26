-------------------------------------------------
-- The Ultimate Volume Widget for Awesome Window Manager
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/volume-widget

-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local spawn = require("awful.spawn")
local watch = require("awful.widget.watch")
local beautiful = require('beautiful')
local wibox = require("wibox")

local GET_VOLUME_CMD = 'amixer -D pulse sget Master'
local function INC_VOLUME_CMD(step) return 'pactl set-sink-volume 0 +' .. step .. '%' end
local function DEC_VOLUME_CMD(step) return 'pactl set-sink-volume 0 -' .. step .. '%' end
local TOG_VOLUME_CMD = 'amixer -D pulse sset Master toggle'

local volume = {}

local function worker()
    local refresh_rate = 1
    local step = 2
    local lastKnownVol = 0
    local lastKnownStatus = 'on'

    volume.widget = wibox.widget {
        {
            id = 'txt',
            font = beautiful.font,
            widget = wibox.widget.textbox
        },
        layout = wibox.layout.fixed.horizontal,
        setInnerText = function(self, new_value)
            self:get_children_by_id('txt')[1]:set_text(new_value)
        end
    }

    local function update_graphic(widget)
        local status
        if lastKnownStatus == 'off' then
            status = string.format("% 3dM ", lastKnownVol)
        else
            status = string.format("% 3d%% ", lastKnownVol)
        end
        widget:setInnerText(status)
    end

    local function updateCachedStatus()
        spawn.easy_async(GET_VOLUME_CMD, function(stdout)
            local volume_level, status = string.match(stdout, "%[(%d+)%%]% %[(%w+)]");
            lastKnownStatus = status;
            lastKnownVol = volume_level;
            update_graphic(volume.widget);
        end)
    end

    function volume:inc()
        lastKnownVol = lastKnownVol + step
        spawn.easy_async(INC_VOLUME_CMD(step), function(stdout) volume:refresh() end)
    end

    function volume:dec()
        lastKnownVol = lastKnownVol - step
        if lastKnownVol < 0 then
            lastKnownVol = 0
        end
        spawn.easy_async(DEC_VOLUME_CMD(step), function(stdout) volume:refresh() end)
    end

    function volume:refresh()
        -- Check if volume is odd, if it is then decrement by 1
        awful.spawn.with_shell("bash ~/.config/awesome/evenVolume.sh");
        spawn.easy_async(GET_VOLUME_CMD, function(stdout) update_graphic(volume.widget) end)
    end

    function volume:toggle()
        if lastKnownStatus == 'on' then
            lastKnownStatus = 'off'
        else
            lastKnownStatus = 'on'
        end

        spawn.easy_async(TOG_VOLUME_CMD, function(stdout) volume:refresh() end)
    end

    volume.widget:buttons(
        awful.util.table.join(
            awful.button({}, 4, function() volume:inc() end),
            awful.button({}, 5, function() volume:dec() end)
        )
    )

    updateCachedStatus()
    watch(GET_VOLUME_CMD, refresh_rate, updateCachedStatus, volume.widget)

    return volume.widget
end

return setmetatable(volume, { __call = function(_, ...) return worker() end })
