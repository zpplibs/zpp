#include <zpp.h>
#include <string>

extern "C" {

// --------------------------------------------------
// ss = std::string

intptr_t
zpp_ss_new(
    const size_t min_capacity,
    const bool resize_to_last_idx,
    char** data_out,
    size_t* capacity_out
) {
    auto buf = new std::string;
    if (min_capacity > 0) {
        buf->reserve(min_capacity);
        if (resize_to_last_idx) buf->resize(buf->capacity() - 1);
    }
    if (data_out != nullptr) *data_out = const_cast<char*>(buf->data());
    if (capacity_out != nullptr) *capacity_out = buf->capacity();
    return (intptr_t)buf;
}

// avoids double-free
bool
zpp_ss_free(intptr_t* ptr) {
    if (ptr == nullptr || *ptr == 0) return false;
    delete (std::string*)*ptr;
    *ptr = 0;
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

/*
size_t
zpp_ss_inc_capacity(const intptr_t ptr,
    const size_t val,
    char** data_out
) {
    if (ptr == 0) return 0;
    auto buf = (std::string*)ptr;
    size_t capacity = buf->capacity();
    capacity += val;
    buf->reserve(capacity);
    if (data_out != nullptr) *data_out = const_cast<char*>(buf->data());
    return capacity;
}
*/

bool
zpp_ss_resize(const intptr_t ptr,
    const size_t size,
    const uint8_t filler,
    const bool preserve_trailing_data,
    char** data_out,
    size_t* capacity_out
) {
    if (ptr == 0) return false;
    auto buf = (std::string*)ptr;
    if (preserve_trailing_data) {
        auto current_size = buf->size();
        auto copy_len = buf->capacity() - current_size;
        if (copy_len > 0) buf->append(buf->data() + current_size, copy_len);
    }
    buf->resize(size, filler);
    //if (filler == 0) buf->resize(size);
    //else buf->resize(size, filler);
    if (data_out != nullptr) *data_out = const_cast<char*>(buf->data());
    if (capacity_out != nullptr) *capacity_out = buf->capacity();
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