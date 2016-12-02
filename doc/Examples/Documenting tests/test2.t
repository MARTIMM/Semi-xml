use v6.c;
use Test;


    my Int $x = 10;

ok $x ~~ Int, 'T0';
todo 'D1', 1;
is $x, 10, 'D2';

    my Int $y = 10;

ok $y ~~ Int, 'T3';
is $y, 10, 'T4';
todo 'D5', 1;
is $y, 11, 'D6';


done-testing;
