using Compress: HashValue, hash, minbytes
using Compress: calc, issafe, DJB2_32, HashFunction, safe_calc, hashtype

@testset "HashValue" begin
    hv = HashValue(10)
    @test hash(hv, UInt32(0)) == UInt32(10)
    @test hash(hv, UInt32(42)) == UInt32(10)

    hv2 = HashValue{UInt32}(13)
    @test hash(hv2, UInt32(0)) == UInt32(13)
    @test hash(hv2, UInt32(42)) == UInt32(13)
end

@testset "DJB2_32" begin
    h = DJB2_32()
    @test typeof(h) <: HashFunction
    @test hashtype(h) == UInt32
    @test minbytes(h) == 1 # It can hash a single byte

    @test !issafe(h, UInt8[],      1, 1)
    @test !issafe(h, UInt8[1],     1, 2)
    @test !issafe(h, UInt8[1, 2],  1, 3)
    @test !issafe(h, UInt8[1, 2],  2, 3)
    @test !issafe(h, UInt8[1, 2],  2, 2)

    @test issafe(h, UInt8[],      1, 0)
    @test issafe(h, UInt8[1],     1, 1)
    @test issafe(h, UInt8[1, 2],  1, 2)
    @test issafe(h, UInt8[1, 2],  2, 1)

    @test issafe(h, UInt8[1, 2, 3],  3, 0)
    @test issafe(h, UInt8[1, 2, 3],  2, 1)
    @test issafe(h, UInt8[1, 2, 3],  1, 2)

    hv = calc(h, UInt8[1], 1, 1)
    @test typeof(hv) == HashValue{UInt32}
    @test hv.v == (5381 * 33 + 1)

    @test calc(h, UInt8[1, 3], 1, 2).v == ((5381 * 33 + 1) * 33 + 3)
    @test calc(h, UInt8[5, 3], 1, 1).v == (5381 * 33 + 5)
    @test calc(h, UInt8[5, 3], 2, 1).v == (5381 * 33 + 3)

    @test safe_calc(h, UInt8[1, 3], 1, 2).v == ((5381 * 33 + 1) * 33 + 3)
    @test safe_calc(h, UInt8[5, 3], 1, 1).v == (5381 * 33 + 5)
    @test safe_calc(h, UInt8[5, 3], 2, 1).v == (5381 * 33 + 3)

    @test_throws ErrorException safe_calc(h, UInt8[5, 3], 1, 3)

    @test safe_calc(h, UInt8[7, 4], 1, [0, 1]).v == ((5381 * 33 + 7) * 33 + 4)
    @test safe_calc(h, UInt8[2, 3, 5], 1, [0, 2]).v == ((5381 * 33 + 2) * 33 + 5)

    # Known collisions for DJB2 according to https://softwareengineering.stackexchange.com/questions/49550/which-hashing-algorithm-is-best-for-uniqueness-and-speed
    @test calc(h, "hetairas").v    == calc(h, "mentioner").v
    @test calc(h, "heliotropes").v == calc(h, "neurospora").v
    @test calc(h, "depravement").v == calc(h, "serafins").v
    @test calc(h, "stylist").v     == calc(h, "subgenera").v
    @test calc(h, "joyful").v      == calc(h, "synaphea").v
    @test calc(h, "redescribed").v == calc(h, "urites").v
    @test calc(h, "dram").v        == calc(h, "vivency").v
end
