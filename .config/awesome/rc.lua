-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")
local switcher = require("awesome-switcher")

local internet_widget = require("internet");
local volume_widget = require("volume")
local caps_widget = require("caps");
local battery_widget = require("battery-widget.battery")
local calendar_widget = require("calendar-widget.calendar")
-- or customized
local cw = calendar_widget({
    theme = "nord",
    placement = "bottom_right",
    radius = 5,
});

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Oops, there were errors during startup!",
        text = awesome.startup_errors
    })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        -- Make sure we don"t go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Oops, an error happened!",
            text = tostring(err)
        })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init("~/.config/awesome/theme.lua")
naughty.config.defaults['icon_size'] = 128


local dbusName = 'org.awesomewm.CustomInterface'
local dbusMatch = "interface='org.awesomewm.CustomInterface', member='MyCustomMessage'"

dbus.request_name("session", dbusName)

dbus.add_match("session", dbusMatch)

dbus.connect_signal(dbusName, function(bus, sender, message, _, _, _)
    if sender == "internet" then
        internet_widget:setStatus(message == "good internet")
    end
end)


-- This is used later as the default terminal and editor to run.
local terminal = "kitty"
local editor = os.getenv("EDITOR") or "code"
local editor_cmd = terminal .. " -e " .. editor

local tags = { "M", "H", "F" };

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
local modkey = "Mod4"
local altkey = "Mod1"


local function file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

local function custom_restart()
    dbus.remove_match("session", dbusMatch)
    dbus.release_name('session', dbusName)

    awesome.restart()
end

local mymainmenu = awful.menu({
    items = {
        { "hotkeys",       function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
        { "edit config",   function() awful.spawn.easy_async(editor .. " .config/awesome/", function() end) end },
        { "open terminal", terminal },
        { "restart",       custom_restart },
        { "quit",          function() awesome.quit() end },
    }
})

menubar.utils.terminal = terminal -- Set the terminal for applications that require it

local timezone = os.date('%z')    -- "+0200"

-- {{{ Wibar
-- Create a textclock widget
local mytextclock = wibox.widget.textclock("%A-%B (UTC" .. timezone .. ") / %Y-%m-%d %T", 1)
mytextclock:connect_signal("button::press", function(_, _, _, button)
    if button == 1 then cw.toggle() end
    if button == 2 then awful.spawn.easy_async("playerctl play-pause", function() end) end
    if button == 4 then volume_widget:inc() end
    if button == 5 then volume_widget:dec() end
end)

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
    awful.button({}, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({}, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then
            client.focus:toggle_tag(t)
        end
    end),
    awful.button({}, 4, function(t)
        volume_widget:inc()
    end),
    awful.button({}, 5, function(t)
        volume_widget:dec()
    end)
)

local tasklist_buttons = gears.table.join(
    awful.button({}, 1, function(c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal(
                "request::activate",
                "tasklist",
                { raise = true }
            )
        end
    end),

    awful.button({}, 2, function(c) awful.spawn.easy_async("playerctl play-pause", function() end) end),
    awful.button({ modkey }, 2, function(c) volume_widget:toggle() end),
    awful.button({}, 4, function() volume_widget:inc() end),
    awful.button({}, 5, function() volume_widget:dec() end))

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen"s geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag(tags, s, awful.layout.layouts[1])

    -- Create an imagebox widget which will contain an icon indicating which layout we"re using.
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons
    }

    -- Create the wibar
    s.mywibox = awful.wibar({ position = "bottom", screen = s, height = 20 })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            s.mytaglist,
        },
        s.mytasklist, -- Middle widget
        {             -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            wibox.widget.systray(),
            volume_widget {},
            internet_widget {},
            caps_widget {},
            battery_widget({
                show_current_level = true
            }),
            mytextclock,
        },
    }
end)
-- }}}

-- {{{ Key bindings
local globalkeys = gears.table.join(
    awful.key({ modkey, "Shift" }, "q", awesome.quit, { description = "quit awesome", group = "awesome" }),
    awful.key({ modkey, "Shift" }, "r", custom_restart, { description = "reload awesome", group = "awesome" }),
    awful.key({ modkey, "Shift" }, "h", function() mymainmenu:show() end,
        { description = "show main menu", group = "awesome" }),
    awful.key({ modkey }, "h", hotkeys_popup.show_help, { description = "show help", group = "awesome" }),

    -- Standard program
    awful.key({ modkey }, "Return", function() awful.spawn.easy_async(terminal, function() end) end,
        { description = "open a terminal", group = "launcher" }),

    -- Menubar
    awful.key({ modkey }, "r",
        function() awful.spawn.easy_async("rofi -drun-use-desktop-cache -show drun", function() end) end,
        { description = "show the menubar", group = "launcher" }),

    -- Media Keys
    -- awful.key({}, "XF86AudioMute", function() volume_widget:toggle() end),
    -- awful.key({}, "XF86AudioPlay", function() awful.spawn.easy_async("playerctl play-pause", function() end) end),
    -- awful.key({}, "XF86AudioPrev", function() awful.spawn.easy_async("playerctl previous", function() end) end),
    -- awful.key({}, "XF86AudioNext", function() awful.spawn.easy_async("playerctl next", function() end) end),
    -- awful.key({}, "XF86AudioRaiseVolume", function()
    --     volume_widget:inc()
    -- end),
    -- awful.key({}, "XF86AudioLowerVolume", function()
    --     volume_widget:dec()
    -- end),

    awful.key({ modkey }, "Escape", function() volume_widget:toggle() end,
        { description = "Toggle playback mute", group = "media" }),
    awful.key({ modkey }, "a", function() awful.spawn.easy_async("playerctl previous", function() end) end,
        { description = "Previous track", group = "media" }),
    awful.key({ modkey }, "d", function() awful.spawn.easy_async("playerctl next", function() end) end,
        { description = "Next track", group = "media" }),
    awful.key({ modkey }, "space", function() awful.spawn.easy_async("playerctl play-pause", function() end) end,
        { description = "Play/Pause track", group = "media" }),

    awful.key({ modkey }, "w", function()
        volume_widget:inc()
    end, { description = "Increment volume", group = "media" }),
    awful.key({ modkey }, "s", function()
        volume_widget:dec()
    end, { description = "Decrease volume", group = "media" }),

    -- Screenshotting
    -- Print = Screen > Clipboard
    -- Control+Print = Screen > Clipboard & File
    -- Super+Shift+S = Region > Clipboard
    -- Super+Control+Shift+S = Region > Clipboard & File
    -- Super+Print = Window > Clipboard
    -- Super+Control+Print = Window > Clipboard & File
    awful.key({}, "Print",
        function()
            awful.spawn.easy_async_with_shell("maim -m 1 | xclip -selection clipboard -t image/png",
                function() end)
        end,
        { description = "Capture screen", group = "screenshot" }),
    awful.key({ "Control" }, "Print",
        function()
            awful.spawn.easy_async_with_shell(
                "maim -m 1 ~/$(date +%Y-%m-%d-%H-%M-%S-%N).png | xclip -selection clipboard -t image/png", function() end)
        end
        , { description = "Capture screen and save it to a file", group = "screenshot" }),
    -- REGION
    awful.key({ modkey, "Shift" }, "s",
        function() awful.spawn.easy_async_with_shell("bash ~/.config/awesome/maimhandler.sh clipboard", function() end) end,
        { description = "Capture region", group = "screenshot" }),
    awful.key({ modkey, "Shift", "Control" }, "s",
        function() awful.spawn.easy_async_with_shell("bash ~/.config/awesome/maimhandler.sh file", function() end) end
        , { description = "Capture region and save it to a file", group = "screenshot" }),
    -- WINDOW
    awful.key({ modkey }, "Print",
        function()
            awful.spawn.easy_async_with_shell(
                "maim -m 1 -i $(xdotool getactivewindow) | xclip -selection clipboard -t image/png", function() end)
        end
        , { description = "Capture window", group = "screenshot" }),
    awful.key({ modkey, "Control" }, "Print",
        function()
            awful.spawn.easy_async_with_shell(
                "maim -m 1 -i $(xdotool getactivewindow) ~/$(date +%Y-%m-%d-%H-%M-%S-%N).png | xclip -selection clipboard -t image/png ~/$(date +%Y-%m-%d-%H-%M-%S-%N).png",
                function() end)
        end
        , { description = "Capture window and save it to a file", group = "screenshot" }),

    -- Alt+Tab
    awful.key({ altkey }, "Tab", function() switcher.switch(1, altkey, "Alt_L", "Shift", "Tab") end),
    awful.key({ altkey, "Shift" }, "Tab", function() switcher.switch(-1, altkey, "Alt_L", "Shift", "Tab") end),
    awful.key({ modkey }, "e", function() awful.spawn.easy_async("nemo", function() end) end,
        { description = "Open Nemo" }),
    awful.key({ modkey }, "b", function() awful.spawn.easy_async("brave", function() end) end,
        { description = "Open browser" }),
    awful.key({ modkey }, "c", function() awful.spawn.easy_async("speedcrunch", function() end) end,
        { description = "Open Calculator" }),


    -- Hidden
    awful.key({ modkey, altkey }, "r",
        function()
            -- Check for an +/-1 offset of the current date because sometimes the timing with obs and this code is not the same
            local currDate = os.time() + 1; -- idk why -1 but it makes the thing work :p
            local filename0 = os.date(os.getenv("HOME") .. "/replay %Y-%m-%d-%H-%M-%S.mkv", currDate);
            local filenamem1 = os.date(os.getenv("HOME") .. "/replay %Y-%m-%d-%H-%M-%S.mkv", currDate - 1);
            local filename1 = os.date(os.getenv("HOME") .. "/replay %Y-%m-%d-%H-%M-%S.mkv", currDate + 1);
            naughty.notify({
                preset = naughty.config.presets.normal,
                title = "Replay buffer",
                text = "Saving replay buffer...",
                timeout = 3
            });
            gears.timer.start_new(1,
                function()
                    if file_exists(filename0) or file_exists(filenamem1) or file_exists(filename1) then
                        naughty.notify({
                            preset = naughty.config.presets.normal,
                            title = "Replay buffer",
                            text = "Replay buffer saved :D",
                            timeout = 3
                        });
                        return false;
                    end
                    return true;
                end
            )
        end
    ),
    awful.key({}, "Caps_Lock", function() caps_widget:toggle() end)
)

local clientkeys = gears.table.join(
    awful.key({ modkey }, "f",
        function(c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        { description = "toggle fullscreen", group = "client" }),
    awful.key({ modkey, "Shift" }, "z", function(c) c:kill() end, { description = "close", group = "client" }),
    awful.key({ modkey, "Control" }, "Return", function(c) c:swap(awful.client.getmaster()) end,
        { description = "move to master", group = "client" }),
    awful.key({ modkey }, "t", function(c) c.ontop = not c.ontop end,
        { description = "toggle keep on top", group = "client" }),
    awful.key({ modkey }, "x", function(c) c.sticky = not c.sticky end,
        { description = "Toggle Sticky", group = "client" }),
    awful.key({ modkey }, "n", function(c) c.minimized = true end, { description = "minimize", group = "client" }),
    awful.key({ modkey }, "m",
        function(c)
            c.maximized = not c.maximized
            c:raise()
        end,
        { description = "(un)maximize", group = "client" }),

    awful.key({ modkey }, "Left", function(client)
        client.maximized = false

        awful.placement.scale(client.focus, {
            to_percent = 0.5,
            direction = "left",
            honor_workarea = true
        })
        awful.placement.scale(client.focus, {
            to_percent = 1,
            direction = "up",
            honor_workarea = true
        })
        client.maximized_vertical = true
        awful.placement.top_left(client.focus)
        client:raise()
    end, { description = "Snap to left", group = "layout" }),

    awful.key({ modkey }, "Right", function(client)
        client.maximized = false
        awful.placement.scale(client.focus, {
            to_percent = 0.5,
            direction = "right",
            honor_workarea = false
        })
        awful.placement.scale(client.focus, {
            to_percent = 1,
            direction = "up",
            honor_workarea = true
        })
        awful.placement.top(client.focus)
        awful.placement.right(client.focus)
        awful.placement.top_right(client.focus)
        client.maximized_vertical = true
        client:raise()
    end, { description = "Snap to right", group = "layout" }),

    awful.key({ modkey, "Shift" }, "Left", function(client)
        client.maximized_vertical = false
        client.maximized = false
        awful.placement.scale(client.focus, {
            to_percent = 0.5,
            direction = "up",
            honor_workarea = true
        })
        awful.placement.scale(client.focus, {
            to_percent = 0.5,
            direction = "right",
            honor_workarea = true
        })
        awful.placement.top_left(client)
    end, { description = "Snap top left", group = "layout" }),

    awful.key({ modkey, "Shift" }, "Right", function(client)
        client.maximized_vertical = false
        client.maximized = false
        awful.placement.scale(client.focus, {
            to_percent = 0.5,
            direction = "up",
            honor_workarea = true
        })
        awful.placement.scale(client.focus, {
            to_percent = 0.5,
            direction = "right",
            honor_workarea = true
        })
        awful.placement.top_right(client)
    end, { description = "Snap top right", group = "layout" }),
    awful.key({ modkey, "Control" }, "Right", function(client)
        client.maximized_vertical = false
        client.maximized = false
        awful.placement.scale(client.focus, {
            to_percent = 0.5,
            direction = "up",
            honor_workarea = true
        })
        awful.placement.scale(client.focus, {
            to_percent = 0.5,
            direction = "right",
            honor_workarea = true
        })
        awful.placement.bottom_right(client)
        client.y = client.y - 20
    end, { description = "Snap bottom right", group = "layout" }),
    awful.key({ modkey, "Control" }, "Left", function(client)
        client.maximized_vertical = false
        client.maximized = false
        awful.placement.scale(client.focus, {
            to_percent = 0.5,
            direction = "up",
            honor_workarea = true
        })
        awful.placement.scale(client.focus, {
            to_percent = 0.5,
            direction = "right",
            honor_workarea = true
        })
        awful.placement.bottom_left(client)
        client.y = client.y - 20
    end, { description = "Snap bottom left", group = "layout" }),


    awful.key({ modkey }, "Up", function(client)
        client.maximized = false
        client.maximized_vertical = false
        awful.placement.scale(client.focus, {
            to_percent = 0.5,
            direction = "up",
            honor_workarea = true
        })
        awful.placement.scale(client.focus, {
            to_percent = 1,
            direction = "left",
            honor_workarea = true
        })
        awful.placement.top(client.focus)
    end, { description = "Snap Up", group = "layout" }),

    awful.key({ modkey }, "Down", function(client)
        client.maximized = false

        awful.placement.scale(client.focus, {
            to_percent = 0.5,
            direction = "down",
            honor_workarea = true
        })
        awful.placement.scale(client.focus, {
            to_percent = 1,
            direction = "left",
            honor_workarea = true
        })

        awful.placement.bottom(client.focus)
        client.y = client.y - 20
    end, { description = "Snap Down", group = "layout" })
)


local gameKeys = gears.table.join(
    awful.key({ modkey }, "f",
        function(c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        { description = "toggle fullscreen", group = "client" }),
    awful.key({ modkey, "Shift" }, "z", function(c) c:kill() end, { description = "close", group = "client" }),
    awful.key({ modkey, "Control" }, "Return", function(c) c:swap(awful.client.getmaster()) end,
        { description = "move to master", group = "client" }),
    awful.key({ modkey }, "t", function(c) c.ontop = not c.ontop end,
        { description = "toggle keep on top", group = "client" }),
    awful.key({ modkey }, "x", function(c) c.sticky = not c.sticky end,
        { description = "Toggle Sticky", group = "client" }),
    awful.key({ modkey }, "n", function(c) c.minimized = true end, { description = "minimize", group = "client" }),
    awful.key({ modkey }, "m",
        function(c)
            c.maximized = not c.maximized
            c:raise()
        end,
        { description = "(un)maximize", group = "client" })
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, #tags do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    tag:view_only()
                end
            end,
            { description = "view tag #" .. i, group = "tag" }),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    awful.tag.viewtoggle(tag)
                end
            end,
            { description = "toggle tag #" .. i, group = "tag" }),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:move_to_tag(tag)
                    end
                end
            end,
            { description = "move focused client to tag #" .. i, group = "tag" }),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:toggle_tag(tag)
                    end
                end
            end,
            { description = "toggle focused client on tag #" .. i, group = "tag" })
    )
end

root.keys(globalkeys)

local clientbuttons = gears.table.join(
    awful.button({}, 1, function(c) c:emit_signal("request::activate", "mouse_click", { raise = true }) end),
    awful.button({ modkey }, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 2, function(c)
        c.maximized = not c.maximized
        c:raise()
    end),
    awful.button({ modkey }, 3, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.resize(c)
    end)
)

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    {
        rule = {},
        properties = {
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen,
            titlebars_enabled = false
        }
    },

    -- Fullscreen Apps
    {
        rule_any = {
            class = {
                "csgo_linux64",
                "cs2",
                "hl2_linux",
                "tf_linux",
                "osu!.exe",
                "steam_app_727",
                "steam_app_207140",
                "osu!",
                "Terraria.bin.x86_64",
                "steam_app_2379780",
                "portal2_linux",
                "Buckshot Roulette",
                "Pinball FX3.exe",
                "Pinball FX.exe",
                "SlimeRancher.x86_64",
                "warfork.x86_64",
                "SpaceChem",
                "LoE.x86_64",
                "Anonfilly.exe",
                "GeometryDash.exe",
                "MLP.exe",
                "gmod",
                "steam_app_4000",
                "steam_app_3218710",
                "steam_app_307780",
                "tetrio-desktop"
            },
            name = {
                "MTA: San Andreas",
                "Grand Theft Auto V"
            }
        },
        properties = { tag = "F", keys = gameKeys }
    },

    -- Minecraft
    {
        rule = {
            class = "^Minecraft",
            name = "^Minecraft"
        },
        properties = { tag = "F", keys = gameKeys, fullscreen = true }
    },

    -- Terraria
    {
        rule = {
            class = "Terraria.bin.x86_64",
            name = "^Terraria"
        },
        properties = { tag = "F", keys = gameKeys }
    },

    -- Terraria/tModLoader
    {
        rule = {
            class = "dotnet",
            name = "^Terraria"
        },
        properties = { tag = "F", keys = gameKeys }
    }
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
        and not c.size_hints.user_position
        and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- }}}

switcher.settings.preview_box = true                                      -- display preview-box
switcher.settings.preview_box_bg = "#000000ff"                            -- background color
switcher.settings.preview_box_border = "#aaaaaaff"                        -- border-color
switcher.settings.preview_box_fps = 75                                    -- refresh framerate
switcher.settings.preview_box_delay = 50                                  -- delay in ms
switcher.settings.preview_box_title_font = { "sans", "italic", "normal" } -- the font for cairo
switcher.settings.preview_box_title_font_size_factor = 0.8                -- the font sizing factor
switcher.settings.preview_box_title_color = { 255, 255, 255, 1 }          -- the font color

switcher.settings.client_opacity = false                                  -- opacity for unselected clients
switcher.settings.client_opacity_value = 0.5                              -- alpha-value for any client
switcher.settings.client_opacity_value_in_focus = 0.5                     -- alpha-value for the client currently in focus
switcher.settings.client_opacity_value_selected = 1                       -- alpha-value for the selected client

switcher.settings.cycle_raise_client = false                              -- raise clients on cycle
gears.timer.start_new(10, function()
    collectgarbage("step", 100000)
    return true
end)

-- awful.spawn.with_shell("bash -c \"pgrep aw-qt || aw-qt > /dev/null 2>&1\"")
-- awful.spawn.easy_async_with_shell("bash -c \"pgrep whatpulse || whatpulse > /dev/null 2>&1\"", function() end)
awful.spawn.easy_async_with_shell("bash ~/.config/awesome/internetCheck.sh", function() end)