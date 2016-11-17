use v6.c;
use Test;


    constant ABC = 10;
    my Int $i;
nok $i.defined, 'T0';
ok $i ~~ Int, 'T1';
todo 'T2', 1;
ok $i !~~ Int, 'T3';
ok $i ~~ Cool, 'T4';

    $i = ABC;
is $i, 10, 'T5';
todo 'T6', 2;
is $i, 11, 'T7';
like $i.Str, /'not 10, but text'/, 'T8';

    for ^10 {
  ok $^a < 7, 'T9';
}


done-testing;
