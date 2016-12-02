use v6.c;
use Test;


    my Int $x = 10;

ok $x ~~ Int, 'T0';
todo 'D1', 1;
is $x, 10, 'D2';

    my Int $y = 10;

ok $y ~~ Int, 'T3';
todo 'D4', 2;
is $y, 10, 'D5';
is $y, 11, 'D6';


done-testing;
