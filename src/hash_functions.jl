""" Used to indicate a HashValue so we need not calc a hash from it (again) when
    used in Dict's etc. """
immutable HashValue{T <: Unsigned}
    v::T
end
HashValue(v) = HashValue{UInt32}(convert(UInt32, v))

""" The hash value of a HashValue need not be calculated, just returned. """
hash{T <: Unsigned}(hv::HashValue{T}, h::T) = hv.v

abstract HashFunction

# The index deltas are what we should add to a position when walking over bytes to calc a hash value.
# This allows for more complex patterns than just a consecutive sequence of bytes.
# The deltas are guaranteed to be sorted from lowest to highest.
const SeqLenToPatterns = Dict{Int, Vector{Int}}()

patternforseqlen(len::Int) = vcat(Int[0], ones(Int, len-1)) # Don't add anything for first and then add one pre each next byte

function calc(h::HashFunction, src::Vector{UInt8}, pos::Int, seqlen::Int)
    idxpattern = get!(SeqLenToPatterns, seqlen) do
        patternforseqlen(seqlen)
    end
    calc(h, src, pos, idxpattern)
end

calc(h::HashFunction, s::AbstractString, pos::Int = 1, seqlen::Int = length(s)) =
    calc(h, convert(Vector{UInt8}, s), pos, seqlen)

calc(h::HashFunction, s::AbstractString, pos::Int, idxdeltas::Vector{Int}) = 
    calc(h, convert(Vector{UInt8}, s), pos, idxdeltas)

issafe(h::HashFunction, src::Vector{UInt8}, pos::Int, seqlen::Int) = ((pos + seqlen - 1) <= length(src))
issafe(h::HashFunction, src::Vector{UInt8}, pos::Int, idxdeltas::Vector{Int}) = issafe(h, src, pos, sum(idxdeltas))

function safe_calc(h::HashFunction, src::Vector{UInt8}, pos::Int, seqlen::Int)
    issafe(h, src, pos, seqlen) || error("Hashvalue access extends past end of array!")
    calc(h, src, pos, seqlen)
end

function safe_calc(h::HashFunction, src::Vector{UInt8}, pos::Int, idxdeltas::Vector{Int})
    issafe(h, src, pos, idxdeltas) || error("Hashvalue access extends past end of array!")
    calc(h, src, pos, idxdeltas)
end

# We use djb2 hash function as described on page http://www.cse.yorku.ca/~oz/hash.html
type DJB2_32 <: HashFunction; end
hashtype(h::DJB2_32) = UInt32
minbytes(h::DJB2_32) = 1 # Can hash a single byte

const DJB2_Magic_Seed = UInt32(5381)

""" Calculate a hash value starting from `pos' and using the idx delta pattern in idxdeltas. 
    For speed this assumes that pos+sum(idxdeltas) <= length(src), i.e. that there are enough"""
function calc(h::DJB2_32, src::Vector{UInt8}, pos::Int, idxdeltas::Vector{Int})
    hash = DJB2_Magic_Seed
    for delta in idxdeltas
        pos += delta
        hash = ((hash << 5) + hash) + src[pos]
        # hash = hash * 33 + src[pos]
    end
    return HashValue{UInt32}(hash)
end