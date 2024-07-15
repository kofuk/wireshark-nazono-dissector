local nazono = Proto("nazono", "Nazono Protocol")

f_length = ProtoField.new("Length", "nazono.length", ftypes.UINT32)
f_data = ProtoField.new("Data", "nazono.data", ftypes.STRING)

nazono.fields = { f_length, f_data }

local tcp_stream = Field.new("tcp.stream")

function bitxor(b1, b2)
    local result = 0
    for i = 0, 7 do
        if (b1 % 2) ~= (b2 % 2) then
            result = result + 2^i
        end
        b1 = math.floor(b1 / 2)
        b2 = math.floor(b2 / 2)
    end
    return result
end

function decode(buffer, key)
    local result = ByteArray.new()
    for i = 1, buffer:len() do
        result:set_size(result:len() + 1)
        result:set_index(i - 1, bitxor(buffer(i - 1, 1):uint(), key))
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
        if pinfo.dst_port == 8001 then
            -- First packet must be sent from client to server
            return
        end

        if buffer:len() < 6  then
            pinfo.desegment_len = DESEGMENT_ONE_MORE_SEGMENT
            return buffer:len()
        end

        local initialized = buffer:raw(0, 5) == "HELLO"
        if not initialized then
            -- Magic number is not present
            return
        end

        states[stream] = { key = buffer(5, 1):uint() }
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
