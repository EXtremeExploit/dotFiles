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

local GET_VOLUME_CMD = 'amixer -D pulse sget Master'
local function INC_VOLUME_CMD(step) return 'amixer -D pulse sset Master ' .. step .. '%+' end

local function DEC_VOLUME_CMD(step) return 'amixer -D pulse sset Master ' .. step .. '%-' end

local TOG_VOLUME_CMD = 'amixer -D pulse sset Master toggle'

local widget_types = {
    icon_and_text = require("volume-widget.widgets.text-widget"),
}
local volume = {}

local function worker()
    local refresh_rate = 1
    local step = 2

    volume.widget = widget_types['icon_and_text'].get_widget()

    local function update_graphic(widget, stdout)
        local volume_level, status = string.match(stdout, "%[(%d+)%%]% %[(%w+)]");
        if status == 'off' then
            volume_level = string.format("% 3dM ", volume_level)
        else
            volume_level = string.format("% 3d%% ", volume_level)
        end
        widget:setInnerText(volume_level)
    end

    function volume:inc()
        spawn.easy_async(INC_VOLUME_CMD(step), function(stdout) update_graphic(volume.widget, stdout) end)
    end

    function volume:dec()
        spawn.easy_async(DEC_VOLUME_CMD(step), function(stdout) update_graphic(volume.widget, stdout) end)
    end

    function volume:refresh()
        -- Check if volume is odd, if it is then decrement by 1
        awful.spawn.with_shell("bash ~/.config/awesome/evenVolume.sh");
        spawn.easy_async(GET_VOLUME_CMD, function(stdout) update_graphic(volume.widget, stdout) end)
    end

    function volume:toggle()
        spawn.easy_async(TOG_VOLUME_CMD, function(stdout) update_graphic(volume.widget, stdout) end)
    end

    volume.widget:buttons(
        awful.util.table.join(
            awful.button({}, 4, function() volume:inc() end),
            awful.button({}, 5, function() volume:dec() end)
        )
    )

    watch(GET_VOLUME_CMD, refresh_rate, update_graphic, volume.widget)

    return volume.widget
end

return setmetatable(volume, { __call = function(_, ...) return worker() end })
