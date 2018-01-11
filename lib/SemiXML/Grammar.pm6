use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;

#-------------------------------------------------------------------------------
grammar Grammar {

  # get global object to get tracing info
  my SemiXML::Globals $globals .= instance;

  # Actions initialize
  rule init-doc { <?> { note " " if $globals.trace and $globals.refined-tables<T><parse>; } }

  # A document is only a tag with its content in a body. Defined like this
  # there can only be one toplevel document. In the following body documents
  # can be nested.
  #
  # Possible comments outside toplevel document
  rule TOP {
    <.init-doc>
    <.prelude>          # Any number of characters except a '$'
    [ <?> {
        note "\n", '-' x 80, "\nParse document\n", $/.orig.Str.substr( 0, 80),
             "\n " if $globals.trace and $globals.refined-tables<T><parse>;
      }
      <document>
    ]
    <.post>             # drop remaining characters
  }

  # Rule to pop the current bottomlevel element from the stack. It is not
  # possible to use a rule to add the element to this stack. This happens in
  # the actions method for <tag-spec>.
  #
  rule pop-tag-from-list { <?> }
  rule document {
    <tag-spec> {
      note "Parse: Tag $/<tag-spec>"
        if $globals.trace and $globals.refined-tables<T><parse>;
    }
    <tag-body>* <.pop-tag-from-list>
  }

  # A tag is an identifier prefixed with a symbol to attach several semantics
  # to the tag.
  #
  rule tag-spec { <tag> <attributes> }

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
  #
  rule attributes     { [ <attribute> ]* }

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

  token tag-body {
    # Content body can have child elements.
    [ '[' ~ ']' [ $<keep-as-typed>=<[=]>? [ <body-a> || <document> ]* ] ] ||

    # Content body can not have child elements. All other characters
    # remain unprocessed
    [ '{' ~ '}' [ $<keep-as-typed>=<[=]>? <body-b> ] ] ||

    # Alternative for '{ ... }'
    [ '«'  ~ '»' [ $<keep-as-typed>=<[=]>? <body-c> ] ]
  }

  # opening brackets [ and { must also be escaped. « is weird enaugh.
  token body-a { [ <.escaped-char> || <.entity> || <-[\\\$\[\]]> ]+ }
  token body-b { [ <.escaped-char> || <-[\\\{\}]> ]* }
  token body-c { [ <.escaped-char> || <-[\\»]> ]* }

  token escaped-char { '\\' . }

  # entities must be parsed separately because some of them can
  # use a '#' which interferes with the comment start. This is
  # only necessary in the normal block 'body-a'
  token entity          { '&' <-[;]>+ ';' }

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

  rule prelude { <-[$]>* }
  rule post { \s* $ }
}
