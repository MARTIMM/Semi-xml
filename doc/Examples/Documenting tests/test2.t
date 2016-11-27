use v6.c;
use Test;


    my Int $x = 10;


ok $x ~~ Int, 'T0';
is $x, 10, 'T1';


    my Int $y = 10;


ok $y ~~ Int, 'T2';
is $y, 10, 'T3';



done-testing;
