-- midilooop
--
-- Library for passing midi notes
-- from device to different
-- channel in loop an interface.
-- Use K3/K2 to change params group.
-- Use E2/E3 to change values.

local MidiParams = {}
local Midilooop = {}
local out_ch_counter = 0
local note_set = {}
local selected_params_group = 1
local devices = {}
local midi_device_from
local midi_device_to

function Midilooop.device_event(data)
    if #data == 0 then
        return
    end

    local msg = midi.to_msg(data)
    local device_from_channel_param = params:get("port_from")
    local device_from_channel = device_from_channel_param > 1 and device_from_channel_param  or msg.ch

    local count_to_channel_param = params:get("port_to_count")

    if msg and msg.ch == device_from_channel then
        local note = msg.note
        local out_ch_note_off = note_set[note]

        if msg.type == "note_off" then
            midi_device_to:note_off(note, 0, out_ch_note_off)
        elseif msg.type == "note_on" then
            out_ch_counter = out_ch_counter > count_to_channel_param - 1 and 1 or out_ch_counter + 1
            note_set[note] = out_ch_counter
            midi_device_to:note_on(note, msg.vel, out_ch_counter)
        elseif msg.type == "key_pressure" then
            midi_device_to:key_pressure(note, msg.val, out_ch_note_off)
        end
    end
end

function MidiParams.init()
    midi_device_from = midi.connect(1)
    midi_device_to = midi.connect(2)
    midi_device_from.event = Midilooop.device_event

    for id, device in pairs(midi.vports) do
        devices[id] = device.name
    end

    params:add_group("MIDIPARAMS", 4)
    params:add {
        type = "option",
        id = "midi_device_from",
        name = "Midi from",
        options = devices,
        default = 1,
        action = function(value)
            midi_device_from.event = nil
            midi_device_from = midi.connect(value)
            midi_device_from.event = Midilooop.device_event
        end
    }

    params:add {
        type = "option",
        id = "midi_device_to",
        name = "Midi to",
        options = devices,
        default = 2,
        action = function(value)
            midi_device_to.event = nil
            midi_device_to = midi.connect(value)
        end
    }

    params:add {
        type = "number",
        id = "port_from",
        name = "Port from",
        min = 1,
        max = 16,
        default = 1
    }

    params:add {
        type = "number",
        id = "port_to_count",
        name = "Port to count",
        min = 1,
        max = 16,
        default = 6
    }
end

function redraw()
    screen.clear()
    screen.font_face(0)
    screen.font_size(8)

    -- set level for group 1
    screen.level(selected_params_group == 1 and 15 or 5)
    screen.move(10, 20)
    screen.text("Midi from: " .. devices[params:get("midi_device_from")])
    screen.move(10, 30)
    screen.text("Midi to: " .. devices[params:get("midi_device_to")])

    -- set level for group 2
    screen.level(selected_params_group == 2 and 15 or 5)
    screen.move(10, 40)
    screen.text("Port from: " .. params:get("port_from"))
    screen.move(10, 50)
    screen.text("Port to count: " .. params:get("port_to_count"))
    
    screen.update()
end

function key(n,z)
    if z == 1 then
        if n == 2 then
            selected_params_group = 1
        elseif n == 3 then
            selected_params_group = 2
        end
        redraw()
    end
end

function enc(n,d)
    if selected_params_group == 1 then
        if n == 2 then
            params:delta("midi_device_from", d)
        elseif n == 3 then
            params:delta("midi_device_to", d)
        end
    else
        if n == 2 then
            params:delta("port_from", d)
        elseif n == 3 then
            params:delta("port_to_count", d)
        end
    end
    redraw()
end

function init()
    MidiParams.init()
end
