local bit = require("bit")

local nazono = Proto("nazono", "Nazono Protocol")

f_length = ProtoField.new("Length", "nazono.length", ftypes.UINT32)
f_data = ProtoField.new("Data", "nazono.data", ftypes.STRING)

nazono.fields = { f_length, f_data }

local tcp_stream = Field.new("tcp.stream")

function decode(buffer, key)
    local result = ByteArray.new()
    for i = 1, buffer:len() do
        result:set_size(result:len() + 1)
        result:set_index(i - 1, bit.bxor(buffer(i - 1, 1):uint(), key))
    end
    return result
end

function nazono.init()
    states = {}
end

function nazono.dissector(buffer, pinfo, tree)
    pinfo.cols.protocol = "Nazono"

    local stream = tcp_stream().value
    local state = states[stream]
    if state == nil then
        -- In this implementation, the side that sends the first packet is considered the client.
        -- Alternatively, the side using port 8001 could be considered the server.

        local client_ip = pinfo.src
        local client_port = pinfo.src_port

        if buffer:len() < 6  then
            pinfo.desegment_len = DESEGMENT_ONE_MORE_SEGMENT
            return buffer:len()
        end

        if buffer:raw(0, 5) ~= "HELLO" then
            -- Magic number is not present
            return
        end

        states[stream] = { key = buffer(5, 1):uint(), client_ip = client_ip, client_port = client_port }
        buffer = buffer(6):tvb()
    end

    local key = states[stream].key

    while buffer:len() > 0 do
        if buffer:len() < 4 then
            pinfo.desegment_len = DESEGMENT_ONE_MORE_SEGMENT
            return buffer:len()
        end

        length = decode(buffer(0, 4), key):le_uint()
        if buffer:len() < length + 4  then
            pinfo.desegment_len = DESEGMENT_ONE_MORE_SEGMENT
            return buffer:len()
        end

        local subtree = tree:add(nazono, buffer(0, 4 + length))
        subtree:add(f_length, buffer(0, 4), length)
        subtree:add(f_data, buffer(4, length), decode(buffer(4, length), key):raw())

        buffer = buffer(4 + length):tvb()
    end
end

tcp_table = DissectorTable.get("tcp.port")
tcp_table:add(8001, nazono)
