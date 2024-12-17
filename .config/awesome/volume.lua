local awful = require("awful")
local beautiful = require('beautiful')
local gears = require("gears")
local wibox = require("wibox")

local utils = require('utils');
local isPAOk = utils.isModuleAvailable("pulseaudio") and _VERSION == "Lua 5.4";

if isPAOk then
    pa = require("pulseaudio");
end

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
        if isPAOk then
            local sinks = pa.get_sinks()
            for _, value in pairs(sinks) do
                if value.default then
                    return value;
                end
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
        if isPAOk then
            local sink = getDefaultSink();
            volume = sink.volume or 0;
            isMuted = sink.mute or false;

            if not (volume % 2 == 0) then
                volume = volume - 1;

                pa.set_sink_volume(sink.index, { volume = volume, mute = isMuted });
            end
        end
        widget:refresh();
    end

    function widget:inc()
        if isPAOk then
            local sink = getDefaultSink();
            local newVol = math.min(100, sink.volume + step);
            if sink.volume == newVol then
                return;
            end
            volume = newVol;
            isMuted = sink.mute;

            widget:refresh();
            pa.set_sink_volume(sink.index, { volume = volume, mute = isMuted });
        end
    end

    function widget:dec()
        if isPAOk then
            local sink = getDefaultSink();
            local newVol = math.max(0, sink.volume - step);
            if sink.volume == newVol then
                return;
            end
            volume = newVol;
            isMuted = sink.mute;

            widget:refresh();
            pa.set_sink_volume(sink.index, { volume = volume, mute = isMuted });
        end
    end

    function widget:toggle()
        if isPAOk then
            local sink = getDefaultSink();

            volume = sink.volume;
            isMuted = not sink.mute;

            pa.set_sink_volume(sink.index, { volume = sink.volume, mute = isMuted });
        end
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
