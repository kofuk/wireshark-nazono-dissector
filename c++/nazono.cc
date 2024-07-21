#include <cstdint>

#include <epan/packet.h>

namespace {
    constexpr std::uint16_t PROTO_TAG = 8001;
    int proto_nazono;

    int dissect_nazono(::tvbuff_t *tvb, ::packet_info *pinfo, ::proto_tree *tree, void *data) {
        col_set_str(pinfo->cinfo, COL_PROTOCOL, "Nazono Protocol");
        col_clear(pinfo->cinfo, COL_INFO);

        return tvb_captured_length(tvb);
    }
} // namespace

extern "C" {
void proto_register_nazono(void) {
    proto_nazono = proto_register_protocol("Nazono Protocol", "Nazono", "nazono");
}

void proto_reg_handoff_nazono(void) {
    static dissector_handle_t nazono_handle = create_dissector_handle(dissect_nazono, proto_nazono);
    dissector_add_uint("udp.port", PROTO_TAG, nazono_handle);
}
}
