""" A pattern dictionary counts the number of times certain patterns of chars
    occur in a string / sequence of bytes. A pattern is typically a consecutive
    sequence of bytes but can also use other patterns/templates. """
type PatternDictionary{HT <: Unsigned, CT <: Unsigned}
    patterns::Vector{Vector{Int}}   # Patterns of position deltas to use when checking subsequences
    hashfn::HashFunction            # Hash function used to map
    counts::Dict{HashValue{HT}, CT}            # Counts for each subsequence found when patterns where applied
    numseq::UInt
    PatternDictionary(ps::Vector{Vector{Int}}, hfn::HashFunction = DJB2_32()) = begin
        @assert length(ps) >= 1
        @assert hashtype(hfn) == HT
        new(ps, hfn, Dict{HashValue{HT}, CT}(), 0)
    end
end

numpatterns{HT <: Unsigned, CT <: Unsigned}(pd::PatternDictionary{HT, CT}) = length(pd.counts)
numseq{HT <: Unsigned, CT <: Unsigned}(pd::PatternDictionary{HT, CT}) = pd.numseq

PatternDictionary(seqlen::Int, s::AbstractString, hfn::HashFunction = DJB2_32()) = 
    PatternDictionary(Vector{Int}[patternforseqlen(seqlen)], s, hfn)

function PatternDictionary(patterns::Vector{Vector{Int}}, s::AbstractString, hfn::HashFunction = DJB2_32())
    pd = PatternDictionary{hashtype(hfn), UInt16}(patterns, hfn)
    count_subsequences!(pd, s)
    pd
end

function count_subsequences_for_pattern!{HT <: Unsigned, CT <: Unsigned}(
    pd::PatternDictionary{HT, CT}, src::Vector{UInt8}, 
    pattern::Vector{Int}, startpos::Int = 1, endpos::Int = length(src))

    patternmaxdelta = sum(pattern)
    for pos in startpos:(endpos-patternmaxdelta)
        h = calc(pd.hashfn, src, pos, pattern)
        pd.counts[h] = get!(pd.counts, h, 0) + 1
        pd.numseq += 1
    end
    pd
end

function count_subsequences!{HT <: Unsigned, CT <: Unsigned}(
    pd::PatternDictionary{HT, CT}, src::Vector{UInt8}, 
    startpos::Int = 1, endpos::Int = length(src))

    for p in pd.patterns
        count_subsequences_for_pattern!(pd, src, p, startpos, endpos)
    end
    pd
end

count_subsequences!{HT <: Unsigned, CT <: Unsigned}(
    pd::PatternDictionary{HT, CT}, s::AbstractString, startpos::Int = 1, endpos::Int = length(s)) = 
        count_subsequences!(pd, convert(Vector{UInt8}, s), startpos, endpos)