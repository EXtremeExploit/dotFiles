local awful = require("awful")
local beautiful = require('beautiful')
local gears = require("gears")
local wibox = require("wibox")

local pa = require("pulseaudio");

local widget = {}

local function worker()
    local refresh_rate = 1;
    local step = 2;

    local volume = 0;
    local isMuted = false;

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

    local function getDefaultSink()
        local sinks = pa.get_sinks()
        for _, value in pairs(sinks) do
            if value.default then
                return value;
            end
        end
        return {};
    end

    function widget:refresh()
        local status;
        if isMuted then
            status = string.format("% 3dM ", volume)
        else
            status = string.format("% 3d%% ", volume)
        end
        widget.widget:setInnerText(status);
    end

    local function updateCachedStatus()
        local sink = getDefaultSink();
        volume = sink.volume;
        isMuted = sink.mute;

        if not (volume % 2 == 0) then
            volume = volume - 1;

            pa.set_sink_volume(sink.index, { volume = volume, mute = isMuted });
        end
        widget:refresh();
    end

    function widget:inc()
        local sink = getDefaultSink();
        local newVol = sink.volume + step;
        volume = newVol;
        isMuted = sink.mute;

        widget:refresh();
        pa.set_sink_volume(sink.index, { volume = volume, mute = isMuted });
    end

    function widget:dec()
        local sink = getDefaultSink();
        local newVol = math.max(0, sink.volume - step);
        volume = newVol;
        isMuted = sink.mute;


        widget:refresh();
        pa.set_sink_volume(sink.index, { volume = volume, mute = isMuted });
    end

    function widget:toggle()
        local sink = getDefaultSink();

        volume = sink.volume;
        isMuted = not sink.mute;

        pa.set_sink_volume(sink.index, { volume = sink.volume, mute = isMuted });
        widget:refresh();
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
        callback = updateCachedStatus
    }

    return widget.widget;
end

return setmetatable(widget, { __call = function(_, ...) return worker() end })
