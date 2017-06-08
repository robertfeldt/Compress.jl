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
const SeqLenToIndexDeltas = Dict{Int, Vector{Int}}()

function calc(h::HashFunction, src::Vector{UInt8}, pos::Int, seqlen::Int)
    idxpattern = get!(SeqLenToIndexDeltas, seqlen) do
        collect(0:(seqlen-1))
    end
    calc(h, src, pos, idxpattern)
end

calc(h::HashFunction, s::AbstractString, pos::Int = 1, seqlen::Int = length(s)) =
    calc(h, convert(Vector{UInt8}, s), pos, seqlen)

calc(h::HashFunction, s::AbstractString, pos::Int, idxdeltas::Vector{Int}) = 
    calc(h, convert(Vector{UInt8}, s), pos, idxdeltas)

issafe(h::HashFunction, src::Vector{UInt8}, pos::Int, seqlen::Int) = ((pos + seqlen - 1) <= length(src))
issafe(h::HashFunction, src::Vector{UInt8}, pos::Int, idxdeltas::Vector{Int}) = issafe(h, src, pos, idxdeltas[end])

function safe_calc(h::HashFunction, src::Vector{UInt8}, pos::Int, seqlen::Int)
    issafe(h, src, pos, seqlen) || error("Hashvalue calculation extends past end of array!")
    calc(h, src, pos, seqlen)
end

function safe_calc(h::HashFunction, src::Vector{UInt8}, pos::Int, idxdeltas::Vector{Int})
    issafe(h, src, pos, idxdeltas) || error("Hashvalue calculation extends past end of array!")
    calc(h, src, pos, idxdeltas)
end

# We use djb2 hash function as described on page http://www.cse.yorku.ca/~oz/hash.html
type DJB2_32 <: HashFunction; end
numbits(h::DJB2_32) = 32

const DJB2_Magic_Seed = UInt32(5381)

""" Calculate a hash value starting from `pos' and using the idx delta pattern in idxdeltas. 
    For speed this assumes that pos+idxdeltas[end] <= length(src), i.e. that there are enough"""
function calc(h::DJB2_32, src::Vector{UInt8}, pos::Int, idxdeltas::Vector{Int})
    hash = DJB2_Magic_Seed
    for delta in idxdeltas
        hash = ((hash << 5) + hash) + src[pos + delta]
        # hash = hash * 33 + src[pos]
    end
    return HashValue{UInt32}(hash)
end