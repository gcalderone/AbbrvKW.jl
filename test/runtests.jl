using Base.Test
using AbbrvKW

# Define a structure to be used in tje test
struct TestStruct1
  foo::Int
  bar::Float64
end

function TestFunc(;kw...)
    @AbbrvKW_check(kw,
                   ABool::Bool=true,
                   AnotherBool::Bool=false,
                   AVector::Vector{Int}=[1,2,3],
                   AString::String="foo",
                   ATuple=(1,2),
                   AStruct::TestStruct1=TestStruct1(0, 3.14),
                   Generic="generic"
                   )
    
    return (ABool,
            AnotherBool,
            AVector,
            AString,
            ATuple,
            AStruct,
            Generic
            )
end

a = TestFunc(Gen="baz", AStru=TestStruct1(1, 2), AB=true, Gen="BAZ")
b = (true, false, [1, 2, 3], "foo", (1, 2), TestStruct1(1, 2.0), "BAZ")

for i in 1:length(a)
    @test a[i] == b[i]
end

@test_throws ErrorException a = TestFunc(zzz=1)
