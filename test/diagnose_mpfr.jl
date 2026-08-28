using Giac

println("=" ^ 60)
println("MPFR / multi-precision diagnostic")
println("Julia: ", VERSION)
println("OS:    ", Sys.KERNEL, " ", Sys.MACHINE)
println("=" ^ 60)

g = giac_eval("pi")
println("giac_eval(\"pi\") -> ",
        " type=", Giac.giac_type(g),
        " string=", string(g))

r = Giac.Commands.evalf(g, 100)
s = string(r)
println("Commands.evalf(pi, 100) -> ",
        " type=", Giac.giac_type(r),
        " len(string)=", length(s),
        " string=", s)

r2 = giac_eval("evalf(pi, 100)")
s2 = string(r2)
println("giac_eval(\"evalf(pi, 100)\") -> ",
        " type=", Giac.giac_type(r2),
        " len(string)=", length(s2),
        " string=", s2)

r3 = giac_eval("evalf(sqrt(2), 100)")
s3 = string(r3)
println("giac_eval(\"evalf(sqrt(2), 100)\") -> ",
        " type=", Giac.giac_type(r3),
        " len(string)=", length(s3),
        " string=", s3)

r4 = giac_eval("Digits := 100; evalf(pi)")
s4 = string(r4)
println("Digits := 100; evalf(pi) -> ",
        " type=", Giac.giac_type(r4),
        " len(string)=", length(s4),
        " string=", s4)

println("=" ^ 60)
