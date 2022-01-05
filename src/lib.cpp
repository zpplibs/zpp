#include <zpp.h>
#include <string>

extern "C" {

// --------------------------------------------------
// ss = std::string

intptr_t
zpp_ss_new(const size_t initial_capacity) {
    std::string* buf = new std::string();
    if (initial_capacity > 0) buf->reserve(initial_capacity);
    return (intptr_t)buf;
}

bool
zpp_ss_free(const intptr_t ptr) {
    if (ptr == 0) return false;
    delete (std::string*)ptr;
    return true;
}

bool
zpp_ss_clear(const intptr_t ptr) {
    if (ptr == 0) return false;
    ((std::string*)ptr)->clear();
    return true;
}

size_t
zpp_ss_size(const intptr_t ptr) {
    return ptr == 0 ? 0 : ((std::string*)ptr)->size();
}

size_t
zpp_ss_capacity(const intptr_t ptr) {
    return ptr == 0 ? 0 : ((std::string*)ptr)->capacity();
}

bool
zpp_ss_resize(const intptr_t ptr,
    const size_t size,
    const uint8_t character
) {
    if (ptr == 0) return false;
    ((std::string*)ptr)->resize(size, character);
    return true;
}

char*
zpp_ss_data(const intptr_t ptr, size_t* out_size) {
    if (ptr == 0) return nullptr;
    *out_size = ((std::string*)ptr)->size();
    return const_cast<char*>(((std::string*)ptr)->data());
}

bool
zpp_ss_append(
    const intptr_t ptr,
    const char* data, const size_t data_len,
    const bool clear_before_append
) {
    if (ptr == 0 || data == nullptr) return false;
    if (clear_before_append) ((std::string*)ptr)->assign(data, data_len);
    else ((std::string*)ptr)->append(data, data_len);
    return true;
}

} // "C"