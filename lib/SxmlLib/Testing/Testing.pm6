use v6.c;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<https://github.com/MARTIMM>;

use SemiXML;

enum TestType is export <TestCmd TodoCmd BugCmd SkipCmd>;

our $current-type = TestCmd;
our $type-count = 0;

# counting test, bug, todo and skip commands
our $count = 0;
our $parts = [];
