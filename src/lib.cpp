#include <zpp.h>
#include <string>

extern "C" {

// --------------------------------------------------
// ss = std::string

intptr_t
zpp_ss_new(
    const size_t min_capacity,
    const bool resize_to_capacity,
    char** data_out,
    size_t* capacity_out
) {
    auto buf = new std::string;
    if (min_capacity > buf->capacity()) {
        buf->reserve(min_capacity);
    }
    if (resize_to_capacity) {
        buf->resize_and_overwrite(buf->capacity(), [](char* _, size_t n) noexcept { return n; });
    }
    if (data_out != nullptr) *data_out = const_cast<char*>(buf->data());
    if (capacity_out != nullptr) *capacity_out = buf->capacity();
    return (intptr_t)buf;
}

char*
zpp_ss_init(
    const intptr_t ptr,
    const size_t min_capacity,
    const bool resize_to_capacity,
    size_t* capacity_out
) {
    if (ptr == 0) return nullptr;
    auto buf = (std::string*)ptr;
    if (min_capacity > buf->capacity()) {
        buf->reserve(min_capacity);
    }
    if (resize_to_capacity) {
        buf->resize_and_overwrite(buf->capacity(), [](char* _, size_t n) noexcept { return n; });
    }
    if (capacity_out != nullptr) *capacity_out = buf->capacity();
    
    return const_cast<char*>(buf->data());
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
zpp_ss_set_size(const intptr_t ptr,
    const size_t size,
    char** data_out,
    size_t* capacity_out
) {
    if (ptr == 0) return false;
    
    auto buf = (std::string*)ptr;
    buf->resize_and_overwrite(size, [](char* _, size_t n) noexcept { return n; });
    
    if (data_out != nullptr) *data_out = const_cast<char*>(buf->data());
    if (capacity_out != nullptr) *capacity_out = buf->capacity();
    return true;
}

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
    /*
    if (preserve_trailing_data) {
        auto current_size = buf->size();
        auto copy_len = buf->capacity() - current_size;
        if (copy_len > 0) buf->append(buf->data() + current_size, copy_len);
    }
    buf->resize(size, filler);
    */
    auto grow = size > buf->capacity();
    if (!grow || !preserve_trailing_data) {
        buf->resize(size, filler);
    } else if (buf->capacity() > buf->size()) {
        buf->resize_and_overwrite(buf->capacity(), [](char* _, size_t n) noexcept { return n; });
        buf->reserve(size);
    } else {
        buf->reserve(size);
    }
    
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