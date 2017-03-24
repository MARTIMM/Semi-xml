use v6;

use SemiXML::StringList;

my SemiXML::StringList $lt .= new(:string('t1 t2 t3 t4'));
note $lt.use-as-list ?? `$lt.join(',') !! ~$lt;

$lt .= new( :string('2 3 4 5'), :use-as-list);
note $lt.use-as-list ?? `$lt.join(',') !! ~$lt;
note `$lt[3].Int;
