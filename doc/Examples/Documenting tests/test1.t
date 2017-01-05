use v6.c;
use Test;

constant ABC = 10;
my Int $i;
my Hash $h;
$h<test> = $i;
nok $i.defined, 'T0';
ok $i ~~ Int, 'T1';
todo 'D2', 1;
ok $i !~~ Int, 'D3';
ok $i ~~ Cool, 'T4';
$i = ABC;
is $i, 10, 'T5';
if ?"We are not stupid" {
    skip 'S6', 2;
}
else {
    ok 10 < 7, 'S7';
    ok 11 / 0, 'S8';
}
todo 'D9', 2;
is $i, 11, 'D10';
like $i.Str, /'not 10, but text'/, 'D11';
for ^10 {
    ok $^a < 7, 'T12';
}
for ^11 {
    todo 'D13', 1;
    ok $^a > 8, 'D14';
}
my Int $i2 = 20304;
todo 'B15', 2;
is $i2, 20304, 'B16';
is $i2 - 20305, 1, 'B17';

done-testing;
