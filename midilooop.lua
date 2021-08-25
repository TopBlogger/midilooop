-- midilooop
--
-- library for passing midi notes
-- from device to different
-- channel in loop an interface

local Midilooop = {}
local out_ch_counter = 0
local note_set = {}
local midi_device_from
local midi_device_to


function Midilooop.device_event(data)
    if #data == 0 then
        return
    end

    local msg = midi.to_msg(data)
    local device_from_channel_param = params:get("midi_device_from_channel")
    local device_from_channel = device_from_channel_param > 1 and device_from_channel_param  or msg.ch

    local count_to_channel_param = params:get("count_to_channel")

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

function Midilooop.init()
    midi_device_from = midi.connect(1)
    midi_device_to = midi.connect(2)
    midi_device_from.event = Midilooop.device_event

    devices = {}
    for id, device in pairs(midi.vports) do
        devices[id] = device.name
    end

    params:add_group("MIDILOOOP", 4)
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

    local channels = {}
    for i = 1, 16 do
        table.insert(channels, i)
    end

    params:add {
        type = "option",
        id = "midi_device_from_channel",
        name = "From device channel",
        options = channels,
        default = 1
    }

    params:add {
        type = "option",
        id = "count_to_channel",
        name = "Count loop channels",
        options = channels,
        default = 6
    }
end


function init()
    Midilooop.init()
end