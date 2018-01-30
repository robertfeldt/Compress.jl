immutable PatternDictionary{KN <: Unsigned, CN <: Unsigned}
    pcounts::Dict{KN, CN}
    numpatterns::UInt64
end
numpatterns(dict) = sum(collect(values(dict)))
PatternDictionary(d) = PatternDictionary{keytype(d), valtype(d)}(d, numpatterns(d))

function numsharedpatterns{KN <: Unsigned, CN <: Unsigned}(pd1::PatternDictionary{KN, CN}, 
pd2::PatternDictionary{KN, CN})
    if length(pd2.pcounts) < length(pd1.pcounts)
        pd1, pd2 = pd2, pd1
    end
    count = 0
    for (k, c1) in pd1.pcounts
        if haskey(pd2.pcounts, k)
            count += min(c1, pd2.pcounts[k])
        end
    end
    count
end

# Fast Compression Distance (FCD) à la Cerra2012 "A Fast Compression-based Similarity Measure with Applications to
# Content-based Image Retrieval" (https://arxiv.org/pdf/1210.0758.pdf).
# Actually, it is not clear from their paper if they really use the multiplicity of the
# patterns since in a later paper Besiris adds this and creates new distance measures.
function fcd{KN <: Unsigned, CN <: Unsigned}(pd1::PatternDictionary{KN, CN}, 
    pd2::PatternDictionary{KN, CN})
    if pd2.numpatterns > pd1.numpatterns
        (pd2.numpatterns - numsharedpatterns(pd1, pd2)) / pd2.numpatterns
    else
        (pd1.numpatterns - numsharedpatterns(pd2, pd1)) / pd1.numpatterns
    end
end

fcd(s1::String, s2::String) = fcd(PatternDictionary(LZWpatterns(s1)), PatternDictionary(LZWpatterns(s2)))

# Normalized Dictionary Distance (NDD) à la Macedonas2008. Actually the Besiris2013 paper
# introduces this and calls it NMD for Normalized Multiset Distance so it seems Macedonas
# never used the multiplicity, only the overlap of words. But Besiris also counts all prefixes
# when building the dictionaries, so it seems our implementation here is in between NDD and NMD.
function ndd{KN <: Unsigned, CN <: Unsigned}(pd1::PatternDictionary{KN, CN}, 
    pd2::PatternDictionary{KN, CN})
    minp, maxp = minmax(pd1.numpatterns, pd2.numpatterns)
    (pd1.numpatterns + pd2.numpatterns - numsharedpatterns(pd1, pd2) - minp) / maxp
end

ndd(s1::String, s2::String) = ndd(PatternDictionary(LZWpatterns(s1)), PatternDictionary(LZWpatterns(s2)))

# Count the number of occurences of each pattern in a LZW compressed string without
# actually creating the compressed string itself.
function LZWpatterns(decompressed::String)
    dictsize = 256
    dict     = Dict{String,UInt32}(string(Char(i)) => i for i in range(0, dictsize))
    counts   = Dict{UInt32,UInt32}()
    w        = ""
    for c in decompressed
        wc = string(w, c)
        if haskey(dict, wc)
            w = wc
        else
            # The prefix of wc has been found again so count it
            pattern = dict[w]
            counts[pattern] = get(counts, pattern, 0) + 1
            dict[wc]  = dictsize
            dictsize += 1
            w        = string(c)
        end
    end
    if !isempty(w)
        pattern = dict[w]
        counts[pattern] = get(counts, pattern, 0) + 1
    end
    return counts
end

s1 = "arne"^3
s2 = "arne"^4
pd1 = PatternDictionary(LZWpatterns(s1))
pd2 = PatternDictionary(LZWpatterns(s2))
fcd(pd1, pd2)
ndd(s1, s2)

ndd("1+2", "(1+2)*(3*4)")