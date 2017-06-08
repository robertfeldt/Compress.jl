get16bits(src::Vector{UInt8}, pos::Int) = src[p+1] << 8 + src[p]
signed_char(src::Vector{UInt8}, pos::Int) = (src[pos] > 0xf0) ? (-src[pos]) : src[pos]

# Hsieh SuperFastHash as described here: http://www.azillionmonkeys.com/qed/hash.html
# He licenses it under LGPL so not sure we can use it...
function calc(h::HsiehSuperFastHash, src::Vector{UInt8}, pos::Int, seqlen::Int)
    len = UInt32(len)
    tmp = UInt32(0)
    hash = len
    (len <= 0) && return(0)
    rem = len & 3
    len >>= 2

    # Main loop
    while (len > 0)
        hash  += get16bits(src, pos)
        tmp    = (get16bits(src, pos+2) << 11) ^ hash
        hash   = (hash << 16) ^ tmp
        pos   += 4
        hash  += (hash >> 11)
        len   -= 1
    end

    # Handle end cases
    if rem == 3
        hash += get16bits(src, pos)
        hash ^= hash << 16
        hash ^= (signed_char(src, pos) << 18) # ((signed char)data[sizeof (uint16_t)]) << 18
        hash += hash >> 11
    elseif rem == 2
        hash += get16bits(src, pos)
        hash ^= hash << 11
        hash += hash >> 17
    elseif rem == 1
        hash += signed_char(src, pos) # (signed char)*data;
        hash ^= hash << 10
        hash += hash >> 1
    end

    # Force "avalanching" of final 127 bits
    hash ^= hash << 3
    hash += hash >> 5
    hash ^= hash << 4
    hash += hash >> 17
    hash ^= hash << 25
    hash += hash >> 6

    return hash
end