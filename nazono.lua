local nazono = Proto.new("nazono", "Nazono Protocol")

f_length = ProtoField.new("Length", "nazono.length", ftypes.UINT32)
f_data = ProtoField.new("Data", "nazono.data", ftypes.STRING)

nazono.fields = { f_length, f_data }

function nazono.dissector(buffer, pinfo, tree)
    pinfo.cols.protocol = "Nazono"
    local length = buffer(0, 4):le_uint()

    if length + 4 > buffer:len() then
        pinfo.desegment_len = DESEGMENT_ONE_MORE_SEGMENT
        return buffer:len()
    end

    while buffer:len() > 0 do
        if buffer:len() < 4 then
            pinfo.desegment_len = DESEGMENT_ONE_MORE_SEGMENT
            return buffer:len()
        end

        length = buffer(0, 4):le_uint()
        if buffer:len() < length + 4  then
            pinfo.desegment_len = DESEGMENT_ONE_MORE_SEGMENT
            return buffer:len()
        end

        local subtree = tree:add(nazono, buffer(0, 4 + length))
        subtree:add(f_length, buffer(0, 4), length)
        subtree:add(f_data, buffer(4, length), buffer:raw(4, length))

        buffer = buffer(4 + length):tvb()
    end
end

tcp_table = DissectorTable.get("tcp.port")
tcp_table:add(8001, nazono)
