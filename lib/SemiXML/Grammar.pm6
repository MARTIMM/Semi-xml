use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;
use SemiXML;
use Terminal::ANSIColor;

#-------------------------------------------------------------------------------
grammar Grammar {

  #-----------------------------------------------------------------------------
  sub error ( Match:D $match, Str:D $message is copy ) {

    # number of chars to show before error location
    my Str $t0 = $match.orig.substr( 0, $match.to);
    my Str $t1 = $match.orig.substr($match.to);
    my Int $i = min( $t0.chars, 50) - 1;

    # linenumber where error was found
    temp $/;
    $t0 ~~ m:g/\n/;
    my Int $l = $/[*].elems + 1;

    # below evere \n character is substituted for two, '\' and 'n'.
    # so correct the $i with line number
    $i += $l;

    # substitute \n for readability
    $t0 ~~ s:g/\n/\\n/;
    $t1 ~~ s:g/\n/\\n/;

    $message = [~] "\n", $message,
          " line $l\n... $t0.substr( *-$i, *-0)",  color('red'),
          "\x[23CF]", $t1.substr( 0, 28), color('reset'), "\n\n";

    my X::SemiXML::Parse $x .= new(:$message);
    die $x;
  }

  #-----------------------------------------------------------------------------
  token TOP {
    [ <body-a> ||
      <document> ||
      [ <[\[\]\{\}«»]> {
          error( $/, "Unexpected content body start/close character");
        }
      ]
    ]*
  }

  token document { <tag-spec> <tag-bodies> }

  # A tag is an identifier prefixed with a symbol to attach several semantics
  # to the tag.
  # '<body-a>?' is attached to cope with spaces. When there is no body found it
  # backtracks to only `<tag> <attributes>` and the rest is eaten in the parents
  # production of the body.
  token tag-spec { <tag> <attributes> }

  proto token tag { * }
  token tag:sym<$!>   { <sym> <mod-name> '.' <meth-name> }
  token tag:sym<$>    { <sym> <tag-name> }

  token mod-name      { <.identifier> }
  token meth-name     { <.identifier> }
  token tag-name      { [ <namespace> ':' ]? <element> }
  token element       { <.xml-identifier> }
  token namespace     { <.xml-ns-identifier> }

  # The tag may be followed by attributes. These are key=value constructs. The
  # key is an identifier and the value can be anything. Enclose the value in
  # quotes ' or " when there are whitespace characters in the value.
  # when there are attributes found a content body must follow!
  token attributes    {
    [ [ <.ws> <attribute> ]+ <!before \s* <?[\[\{«]> > {
        error( $/, "Attributes must be followed by a content body");
      }
    ] ||
    [ <.ws> <attribute> ]*
  }

  token attribute     {
    <attr-key> '=' <attr-value-spec> ||
    '='  $<bool-true-attr>=<attr-key> ||
    '=!' $<bool-false-attr>=<attr-key>
  }

  token attr-key      { [<.key-ns> ':' ]? <.key-name> }
  token key-ns        { <.identifier> }
  token key-name      { <.identifier> }

  token attr-value-spec {
    [ "'" ~ "'" $<attr-value>=<.attr-q-value> ]  ||
    [ '"' ~ '"' $<attr-value>=<.attr-qq-value> ] ||
    [ '<' ~ '>' $<attr-value>=$<attr-list-value>=<.attr-pw-value> ] ||
    $<attr-value>=<.attr-s-value>
  }
  token attr-q-value  { [ <.escaped-char> || <-[\']> ]* }
  token attr-qq-value { [ <.escaped-char> || <-[\"]> ]* }
  token attr-pw-value { [ <.escaped-char> || <-[\>]> ]* }
  token attr-s-value  { [ <.escaped-char> || <-[\s]> ]+ }

  token tag-bodies { $<pre-body>=\s* [
      # Content body can have child elements.
      [ $<body-started>=<?> '[' ~ ']' [ <body-a> || <document> ]* ] ||

      # Content body can not have child elements. All other characters
      # remain unprocessed
      [ $<body-started>=<?> '{' ~ '}' [ <body-b> ]* ] ||

      # Alternative for '{ ... }'
      [ $<body-started>=<?> '«' ~ '»' [ <body-c> ]* ]
    ]*
  }

  token body-a {
    [ [ <.escaped-char>+ || <.entity>+ || <comment> || <-[\\\$\[\]\#]>+ ]+ ||
      [ ('[') {
        error( $/,
          "Cannot start a content body with '$0', did you mean '\\$0'?"
        );
      } ]
    ]+
  }

  token body-b {
    [ [ <.escaped-char>+ || <-[\\\{\}]>+ ]+ ||
      [ ('{') {
        error( $/,
          "Cannot start a content body with '$0', did you mean '\\$0'?"
        );
      } ]
    ]+
  }

  token body-c {
    [ [ <.escaped-char>+ || <-[\\«»]>+ ]+ ||
      [ ('«') {
        error( $/,
          "Cannot start a content body with '$0', did you mean '\\$0'?"
        );
      } ]
    ]+
  }

  token escaped-char { '\\' . }

  # entities must be parsed separately because some of them can
  # use a '#' which interferes with the comment start. This is
  # only necessary in the normal block 'body-a'
  token entity          { '&' <-[;]>+ ';' }

  # comment text after '#'
  token comment { \s* '#' \N* \n }

  # See STD.pm6 of perl6. A tenee bit simplified. .ident is precooked and a
  # dash within the string is accepted.
  token identifier { <.ident> [ '-' <.ident> ]* }

  # From w3c https://www.w3.org/TR/xml11/#NT-NameChar
  token xml-identifier { <.name-start-char> <.name-char>* }
  token name-start-char { ':' || <.ns-name-start-char> }
  token name-char { ':' || <.ns-name-char> }

  # From w3c https://www.w3.org/TR/2004/REC-xml-names11-20040204/#ns-decl
  token xml-ns-identifier { <.ns-name-start-char> <.ns-name-char>* }

  # Don't know which characters are covered by the :Alpha definition so I take
  # the description from the w3c
  token ns-name-start-char {
    <[_ A..Z a..z]> || <[\xC0..\xD6]> || <[\xD8..\xF6]> || <[\xF8..\x2FF]> ||
    <[\x370..\x37D]> || <[\x37F..\x1FFF]> || <[\x200C..\x200D]> ||
    <[\x2070..\x218F]> || <[\x2C00..\x2FEF]> || <[\x3001..\xd7ff]> ||
    <[\xf900..\xfdcf]> || <[\xFDF0..\xFFFD]> || <[\x10000..\xEFFFF]>
  }

  token ns-name-char {
    <.name-start-char> | <[- . 0..9]> | <[\xB7]> |
    <[\x0300..\x036F]> | <[\x203F..\x2040]>
  }
}
