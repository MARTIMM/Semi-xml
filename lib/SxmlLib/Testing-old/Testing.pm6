use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib::Testing:auth<github:MARTIMM>;

#use SemiXML::Sxml;
use SxmlLib::SxmlHelper;

enum TestType is export <TestCmd TodoCmd BugCmd SkipCmd>;

our $current-type = TestCmd;
our $type-count = 0;

# counting test, bug, todo and skip commands
our $count = 0;
our $parts = [];
