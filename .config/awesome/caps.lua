local beautiful = require('beautiful')
local gears = require("gears")
local wibox = require("wibox")


local utils = require('utils');
local isXKBok = utils.isModuleAvailable("xindicators") and _VERSION == "Lua 5.4";
if (isXKBok) then
    xkb = require('xindicators')
end

local caps = {}

local function worker()
    local refresh_rate = 5;

    local lastKnownCaps = 0;

    caps.widget = wibox.widget {
        {
            id = 'txt',
            font = beautiful.font,
            widget = wibox.widget.textbox
        },
        align = "center",
        valign = "center",
        forced_width = 10,
        layout = wibox.layout.fixed.horizontal,
        setInnerText = function(self, new_value)
            self:get_children_by_id('txt')[1]:set_text(new_value)
        end
    }

    local function updateCachedStatus()
        if (isXKBok) then
            lastKnownCaps = xkb.caps_lock();
        end
        caps:refresh()
    end

    function caps:refresh()
        if lastKnownCaps > 0 then
            caps.widget:setInnerText("A");
        else
            caps.widget:setInnerText("a");
        end
    end

    function caps:toggle()
        if lastKnownCaps > 0 then
            lastKnownCaps = 0;
        else 
            lastKnownCaps = 1;
        end
        caps:refresh();
    end

    gears.timer {
        timeout = refresh_rate,
        call_now = true,
        autostart = true,
        callback = updateCachedStatus
    }

    return caps.widget
end

return setmetatable(caps, { __call = function(_, ...) return worker() end })
