#pragma once

#ifndef __cplusplus
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#else
#include <cstddef>
#include <cstdint>
extern "C" {
#endif

// --------------------------------------------------
// c calling to zig

bool
zpp_array_list_u8_append_slice(
    const void* list_ptr,
    const char* data,
    const size_t data_len
);

// --------------------------------------------------
// ss = std::string

intptr_t
zpp_ss_new(
    const size_t min_capacity,
    const bool resize_to_last_idx,
    char** data_out,
    size_t* capacity_out
);

bool
zpp_ss_free(intptr_t* ptr);

/// sets the size to 0
bool
zpp_ss_clear(const intptr_t ptr);

size_t
zpp_ss_size(const intptr_t ptr);

size_t
zpp_ss_capacity(const intptr_t ptr);

/*
/// increment the capacity by the value provided
size_t
zpp_ss_inc_capacity(const intptr_t ptr,
    const size_t val,
    char** data_out
);
*/

bool
zpp_ss_resize(const intptr_t ptr,
    const size_t size,
    const uint8_t filler,
    const bool preserve_trailing_data,
    char** data_out,
    size_t* capacity_out
);

char*
zpp_ss_data(const intptr_t ptr, size_t* out_size);

bool
zpp_ss_append(
    const intptr_t ptr,
    const char* data, const size_t data_len,
    const bool clear_before_append
);

#ifdef __cplusplus
}
#endif