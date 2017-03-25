use v6;

use SemiXML::StringList;

my SemiXML::StringList $lt .= new( :string('t1 t2 t3 t4'), :!use-as-list);
note "\n", ($lt.use-as-list ?? @$lt.join(',') !! ~$lt);
note "Value: $lt.value().join('--')";

$lt .= new( :string('2 3 4 5'), :use-as-list);
note "\n", $lt.use-as-list ?? @$lt.join(',') !! ~$lt;
note (@$lt)[3];
note @$lt[2];
note @$lt[0];
note "Value: $lt.value().join('--')";

$lt .= new( :string('3.23:4.343:90:2e2:1.2e-1'), :delimiter<:>, :use-as-list);
note "\n", $lt.use-as-list ?? @$lt.join(',') !! ~$lt;
note (@$lt)[3];
note @$lt[2];
note [+](@$lt[*]);
note "Value: $lt.value().join('--')";
