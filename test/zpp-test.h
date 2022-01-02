#pragma once

#include <zpp.h>

#ifdef __cplusplus
extern "C" {
#endif

// c calling to zig
inline bool call_zpp_array_list_u8_append(
    void* list_ptr,
    const char* data,
    const size_t data_len
) {
    return zpp_array_list_u8_append(
        list_ptr,
        data,
        data_len
    );
}

#ifdef __cplusplus
}
#endif