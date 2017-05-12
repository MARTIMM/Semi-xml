use v6;
use Test;
use SemiXML::StringList;

my SemiXML::StringList $lt;

#------------------------------------------------------------------------------
dies-ok {$lt(:delimiter<;>)}, '$lt is not instantiated';

$lt .= new( :string('t1 t2 t3 t4'), :!use-as-list);
nok $lt.use-as-list, "string not used as list";
is $lt.value, 't1 t2 t3 t4', ".value '$lt' returned a string";

$lt .= new( :string('2 3 4 5'), :use-as-list);
ok $lt.use-as-list, "string used as list: " ~ $lt.value.join(', ');
is $lt.value.elems, 4, ".value of '$lt' returned a list";
is @$lt[2], 4, '3rd item is 4';
is @$lt[0], 2, '1st item is 2';

$lt .= new( :string('3.23:4.343:90:2e2:1.2e-1'), :delimiter<:>, :use-as-list);
is [+](@$lt[*]), 297.693, "sum of values in string '$lt' is 297.693";

is '3.23:4.343:90:2e2:1.2e-1', $lt(:delimiter(' '))[0],
   "Change delim, 1st item is '$lt'";
is '3=4=5=6=7', $lt(:string('3 4 5 6 7')).join('='), "List now '$lt'";

$lt .= new;
ok !$lt, "no string in object";

my List $v = $lt(
  :string('5.2, 3.5, 2'), :delimiter(/\s* <[,.]> \s*/), :use-as-list
);
is ([+] |@$v[*]), 17, "sum of integers of '$lt' using regex delimiter: 17";

done-testing;
