set console wru=034
set cpu 256k

set ge enabled
att -u ge 10001

set dtc dct=01
att dtc2 ut2.dta

load -i its.138bin
go 100
