#pragma once

#ifndef __cplusplus
#include <stdbool.h>
#include <stddef.h>
#else
extern "C" {
#endif

// c calling to zig
bool zpp_array_list_u8_append(
    void* list_ptr,
    const char* data,
    const size_t data_len
);

#ifdef __cplusplus
}
#endif