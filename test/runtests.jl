using Base.Test
using AbbrvKW

@AbbrvKW function t1()                       
    x=1 
end
@test t1() == 1

@AbbrvKW function t2(x)
    x 
end
@test t2(9) == 9

@AbbrvKW function t3(x, y)
    (x, y)
end
@test t3(3,5) == (3,5)  

@AbbrvKW function t4(x, y=12) 
    (x, y)
end
@test t4(2) == (2,12)   

@AbbrvKW function t5(x, y=12;)
    (x, y)
end
@test t5(3) == (3,12)  

@AbbrvKW function t6(x, y=12; k=13) 
    (x, y, k)
end
@test t6(1) == (1,12,13)
@test t6(1, k=1) == (1,12,1)

@AbbrvKW function t7(x, y=12; key=13)
    (x, y, key)
end
@test t7(0,1) == (0,1,13) 
@test t7(0,2,k=3) == (0,2,3) 
@test t7(0,2,ke=3) == (0,2,3) 
@test t7(0,2,key=3) == (0,2,3)

@AbbrvKW function t8(x, y=12; key=13, key1=20) 
    (x, y, key, key1)
end
@test t8(0) == (0, 12, 13, 20)
@test t8(0, key=-1) == (0, 12, -1, 20)
@test t8(0, key1=-1) == (0, 12, 13, -1)
@test t8(0, key=-1, key1=-2) == (0, 12, -1, -2)
@test_throws MethodError t8(0, ke=0)

@AbbrvKW function t9(x, y=12; key1=13, key2=20) 
    (x, y, key1, key2)
end
@test t9(0) == (0, 12, 13, 20)
@test t9(0, key1=-1) == (0, 12, -1, 20)
@test t9(0, key2=-1) == (0, 12, 13, -1)
@test t9(0, key1=-1, key2=-2) == (0, 12, -1, -2)
@test_throws MethodError t9(0, ke=0)

@AbbrvKW function t9(x, y=12; key=13, keyA=20); (x, y, key)
end


# Test structure
struct TestStruct1
  foo::Int
  bar::Float64
end

@AbbrvKW function TestFunc(;ABool::Bool=true,
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
            Generic)
end

a = TestFunc(Gen="baz", AStru=TestStruct1(1, 2), AB=true, Gen="BAZ")
b = (true, false, [1, 2, 3], "foo", (1, 2), TestStruct1(1, 2.0), "BAZ")

for i in 1:length(a)
    @test a[i] == b[i]
end

@test_throws ErrorException a = TestFunc(zzz=1)


@AbbrvKW function Foo(;Keyword::Int=1, verboseLevel::Union{Void,Int}=nothing, kw...)
    println("Keyword: ", Keyword)
    if verboseLevel != nothing
        println("New verbosity level: ", verboseLevel)
        return (Keyword, verboseLevel)
    end
    return Keyword
end

@test Foo() == 1
@test Foo(K=2) == 2
@test Foo(v=3) == (1,3)
@test Foo(ver=3, Keyw=4) == (4,3)
@test Foo(Keywo=4, ve=3) == (4,3)
@test Foo(Keyword=4, ve=3) == (4,3)
@test Foo(K=4, verboseLevel=3) == (4,3)
@test Foo(bar=2) == 1
