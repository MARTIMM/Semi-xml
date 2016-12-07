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

    my Int $z = 5;
    for ^$z -> $t {

todo 'B7', 1;
ok $t < $z - 3, 'B8';
}


is $z, 5, 'T9';
is $z, 6, 'T10';
if not True {

skip 'S11', 2;
}

    else {

is $z, 7, 'S12';
is $z, 5, 'S13';
}


    my $k = $*KERNEL;
 
if $k.name eq 'linux' {

skip 'S14', 2;
 
} else {

ok $k.name, "win32", 'S15';
ok $k.name, "macos", 'S16';
 
}



done-testing;
