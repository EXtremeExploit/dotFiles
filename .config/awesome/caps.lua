local awful = require("awful")
local beautiful = require('beautiful')
local wibox = require("wibox")

local GET_STATUS_CMD = "xset q | grep Caps"

local caps = {}

local function worker()
    local lastKnownStatus = 'on'

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

    local function update_graphic(widget)
        local status
        if lastKnownStatus == 'off' then
            status = "a"
        else
            status = "A"
        end
        widget:setInnerText(status)
    end

    local function updateCachedStatus()
        caps:refresh()
    end

    function caps:refresh()
        awful.spawn.easy_async(GET_STATUS_CMD,
            function(stdout)
                if stdout:match("Caps Lock") then
                    local status = stdout:gsub(".*(Caps Lock:%s+)(%a+).*", "%2")
                    lastKnownStatus = status
                    update_graphic(caps.widget)
                end
            end
        )
    end

    function caps:toggle()
        if lastKnownStatus == 'on' then
            lastKnownStatus = 'off'
        else
            lastKnownStatus = 'on'
        end

        update_graphic(caps.widget)
    end

    caps:refresh()
    awful.widget.watch(GET_STATUS_CMD, 1, updateCachedStatus, caps.widget)

    return caps.widget
end

return setmetatable(caps, { __call = function(_, ...) return worker() end })
