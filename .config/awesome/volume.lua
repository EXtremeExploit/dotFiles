local awful = require("awful")
local beautiful = require('beautiful')
local gears = require("gears")
local wibox = require("wibox")

local widget = {}

local function worker()
    local refresh_rate = 5;
    local step = 2;

    local volume = 0;
    local muted = false;

    widget.widget = wibox.widget {
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

    function widget:refresh()
        if muted then
            widget.widget:setInnerText(string.format("% 3dM ", volume));
        else
            widget.widget:setInnerText(string.format("% 3d%% ", volume));
        end
    end

    local function read_status(callback)
        awful.spawn.easy_async_with_shell(
            "wpctl get-volume @DEFAULT_AUDIO_SINK@",
            function(out)
                local v = tonumber(out:match("(%d+%.?%d*)")) or 0
                volume = math.floor(v * 100 + 0.5)
                muted = out:match("MUTED") ~= nil
                if callback then callback() end
            end
        )
    end

    local function set_volume()
        -- clamp to 0–100
        volume = math.max(0, math.min(100, volume))
        awful.spawn(
            string.format(
                "wpctl set-volume @DEFAULT_AUDIO_SINK@ %.2f",
                volume / 100
            )
        )
    end

    local function toggle_mute()
        awful.spawn("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
    end

    function widget:inc()
        read_status(function()
            volume = volume + step
            set_volume()
            widget:refresh()
        end)
    end

    function widget:dec()
        read_status(function()
            volume = volume - step
            set_volume()
            widget:refresh()
        end)
    end

    function widget:toggle()
        toggle_mute()
        read_status(widget.refresh)
    end

    widget.widget:buttons(
        awful.util.table.join(
            awful.button({}, 4, function() widget:inc() end),
            awful.button({}, 5, function() widget:dec() end)
        )
    )

    gears.timer {
        timeout = refresh_rate,
        call_now = true,
        autostart = true,
        callback = function()
            read_status(widget.refresh)
        end
    }

    return widget.widget;
end

return setmetatable(widget, { __call = function(_, ...) return worker() end })
