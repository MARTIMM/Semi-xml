use v6.c;
use Test;

use SemiXML;

    constant ABC = 10;

    my Int $i;
ok $i ~~ Int, 'T1';
$i = ABC;
is $i, 10, 'T2';


done-testing;
