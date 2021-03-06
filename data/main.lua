-- Main script of the quest.

local console = sol.main.load_file("console")()

local debug_enabled = false
function sol.main.is_debug_enabled()
  return debug_enabled
end

-- Event called when the program starts.
function sol.main:on_started()

  -- Load built-in settings (audio volume, video mode, etc.).
  sol.main.load_settings()

  -- If there is a file called "debug" in the write directory, enable debug mode.
  debug_enabled = sol.file.exists("debug")

  -- Show the Solarus logo initially.
  local solarus_logo_menu = require("menus/solarus_logo")
  sol.main:start_menu(solarus_logo_menu)
end

function sol.main:on_finished()

  sol.main.save_settings()
end

function sol.main:debug_on_key_pressed(key, modifiers)

  local handled = true
  if key == "f1" then
    if sol.game.exists("save1.dat") then
      self:start_savegame(sol.game.load("save1.dat"))
    end
  elseif key == "f2" then
    if sol.game.exists("save2.dat") then
      self:start_savegame(sol.game.load("save2.dat"))
    end
  elseif key == "f3" then
    if sol.game.exists("save3.dat") then
      self:start_savegame(sol.game.load("save3.dat"))
    end
  elseif key == "f12" and not console.enabled then
    console:start()
  elseif sol.main.game ~= nil and not console.enabled then
    local game = sol.main.game
    local hero = nil
    if game ~= nil and game:get_map() ~= nil then
      hero = game:get_map():get_entity("hero")
    end

    -- In-game cheating keys.
    if key == "p" then
      game:add_life(12)
    elseif key == "m" then
      game:remove_life(2)
    elseif key == "o" then
      game:add_money(50)
    elseif key == "l" then
      game:remove_money(15)
    elseif key == "i" then
      game:add_magic(10)
    elseif key == "k" then
      game:remove_magic(4)
    elseif key == "kp 7" then
      game:set_max_magic(0)
    elseif key == "kp 8" then
      game:set_max_magic(42)
    elseif key == "kp 9" then
      game:set_max_magic(84)
    elseif key == "kp 1" then
      local tunic = game:get_item("tunic")
      local variant = math.max(1, tunic:get_variant() - 1)
      tunic:set_variant(variant)
      game:set_ability("tunic", variant)
    elseif key == "kp 4" then
      local tunic = game:get_item("tunic")
      local variant = math.min(3, tunic:get_variant() + 1)
      tunic:set_variant(variant)
      game:set_ability("tunic", variant)
    elseif key == "kp 2" then
      local sword = game:get_item("sword")
      local variant = math.max(1, sword:get_variant() - 1)
      sword:set_variant(variant)
    elseif key == "kp 5" then
      local sword = game:get_item("sword")
      local variant = math.min(4, sword:get_variant() + 1)
      sword:set_variant(variant)
    elseif key == "kp 3" then
      local shield = game:get_item("shield")
      local variant = math.max(1, shield:get_variant() - 1)
      shield:set_variant(variant)
    elseif key == "kp 6" then
      local shield = game:get_item("shield")
      local variant = math.min(3, shield:get_variant() + 1)
      shield:set_variant(variant)
    elseif key == "g" and hero ~= nil then
      local x, y, layer = hero:get_position()
      if layer ~= 0 then
	hero:set_position(x, y, layer - 1)
      end
    elseif key == "t" and hero ~= nil then
      local x, y, layer = hero:get_position()
      if layer ~= 2 then
	hero:set_position(x, y, layer + 1)
      end
    else
      -- Not a known in-game debug key.
      handled = false
    end
  else
    -- Not a known debug key.
    handled = false
  end

  return handled
end

-- If debug is enabled, the shift key skips dialogs
-- and the control key traverses walls.
local hero_movement = nil
local ctrl_pressed = false
function sol.main:on_update()

  if sol.main.is_debug_enabled() then
    local game = sol.main.game
    if game ~= nil then

      if game:is_dialog_enabled() then
        if sol.input.is_key_pressed("left shift") or sol.input.is_key_pressed("right shift") then
          game.dialog_box:show_all_now()
        end
      end

      local hero = game:get_hero()
      if hero ~= nil then
        if hero:get_movement() ~= hero_movement then
          -- The movement has changed.
          hero_movement = hero:get_movement()
          if hero_movement ~= nil
              and ctrl_pressed
              and not hero_movement:get_ignore_obstacles() then
            -- Also traverse obstacles in the new movement.
            hero_movement:set_ignore_obstacles(true)
          end
        end
        if hero_movement ~= nil then
          if not ctrl_pressed
              and (sol.input.is_key_pressed("left control") or sol.input.is_key_pressed("right control")) then
            hero_movement:set_ignore_obstacles(true)
            ctrl_pressed = true
          elseif ctrl_pressed
              and (not sol.input.is_key_pressed("left control") and not sol.input.is_key_pressed("right control")) then
            hero_movement:set_ignore_obstacles(false)
            ctrl_pressed = false
          end
        end
      end
    end
  end
end

-- Event called when the player pressed a keyboard key.
function sol.main:on_key_pressed(key, modifiers)

  local handled = false

  -- Debugging features.
  if sol.main.is_debug_enabled() then
    handled = sol.main:debug_on_key_pressed(key, modifiers)
  end

  -- Normal features.
  if not handled then

    if key == "f5" then
      -- F5: change the video mode.
      sol.video.switch_mode()
    elseif key == "return" and (modifiers.alt or modifiers.control) then
      -- Alt + Return or Ctrl + Return: switch fullscreen.
      sol.video.set_fullscreen(not sol.video.is_fullscreen())
    elseif key == "f4" and modifiers.alt then
      -- Alt + F4: stop the program.
      sol.main.exit()
    end
  end

  return handled
end

-- Stops the current menu and start another one.
function sol.main:start_menu(menu)

  if sol.main.menu ~= nil then
    sol.menu.stop(sol.main.menu)
  end

  sol.main.menu = menu

  if menu ~= nil then
    sol.menu.start(sol.main, menu)
  end
end

-- Stops the current menu if any and starts a game.
function sol.main:start_savegame(game)

  if sol.main.menu ~= nil then
    sol.menu.stop(sol.main.menu)
  end

  sol.main.menu = nil

  local play_game = sol.main.load_file("play_game")
  play_game(game)
end

