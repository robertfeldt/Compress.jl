using Compress: PatternDictionary, patternforseqlen, count_subsequences!, numpatterns, numseq

@testset "PatternDictionary" begin
    pd = PatternDictionary{UInt32, UInt16}([Int[0, 1]])
    @test typeof(pd) <: PatternDictionary
    count_subsequences!(pd, "arn")
    @test numpatterns(pd) == 2 # only the "ar" and "rn" patterns should be added
    @test numseq(pd) == 2

    pd2 = PatternDictionary(2, "arn")
    @test typeof(pd2) <: PatternDictionary
    @test numpatterns(pd2) == 2 # only the "ar" and "rn" patterns should be added
    @test numseq(pd2) == 2

    pd3 = PatternDictionary(3, "aaaaa")
    @test numpatterns(pd3)   == 1 # only "aaa" should be added 3 times
    @test numseq(pd3)        == 3

    patterns = map(patternforseqlen, Int[2, 5])
    pd4 = PatternDictionary(patterns, "aa1aab")
    # patterns for 2: "aa", "a1", "1a", "aa", "ab"
    # patterns for 5: "aa1aa", "a1aab" 
    @test numpatterns(pd4)   == 6
    @test numseq(pd4)        == 7
end

@testset "patternforseqlen" begin
    @test patternforseqlen(1) == Int[0]
    @test patternforseqlen(2) == Int[0, 1]
    @test patternforseqlen(3) == Int[0, 1, 1]
    @test patternforseqlen(4) == Int[0, 1, 1, 1]
    @test patternforseqlen(7) == Int[0, 1, 1, 1, 1, 1, 1]
end
