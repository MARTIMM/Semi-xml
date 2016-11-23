use v6.c;
use Test;


    constant ABC = 10;
    my Int $i;
nok $i.defined, 'T0';
ok $i ~~ Int, 'T1';
todo 'D2', 1;
ok $i !~~ Int, 'D3';
ok $i ~~ Cool, 'T4';

    $i = ABC;
is $i, 10, 'T5';
todo 'D6', 2;
is $i, 11, 'D7';
like $i.Str, /'not 10, but text'/, 'D8';

    for ^10 {
  ok $^a < 7, 'T9';
}

    for ^11 {
todo 'D10', 11;
  ok $^a > 8, 'D11';
}

    my Int $i2 = 20304;
todo 'B12', 2;
is $i2, 20304, 'B13';
is $i2 - 20305, 1, 'B14';


done-testing;
