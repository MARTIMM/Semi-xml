use v6.c;
#use Grammar::Tracer;

package SemiXML:auth<https://github.com/MARTIMM> {

  grammar Grammar {

    # A complete document looks like the following of which the prelude an dashes
    # are optional
    #
    # ---
    # prelude
    # ---
    # document
    #
    rule TOP {
#      ( <.comment>* "---" <.prelude> "---" ) ** 0..1 <.document>
      <.document>
    }

    # A document is only a tag with its content. Defined like this there can only
    # be one toplevel document.
    #
#    token document { <.comment>* <.tag> <.tag-body> <.comment>* }
    token document { <.tag-spec> <.tag-body> }

    # A tag is an identifier prefixed with a symbol to attach several semantics
    # to the tag.
    #

    rule tag-spec { <tag> <attributes> }

    proto token tag {*}
    token tag:sym<$.>   { <sym> <mod-name> '.' <meth-name> }
    token tag:sym<$!>   { <sym> <mod-name> '.' <meth-name> }
    token tag:sym<$|*>  { <sym> <tag-name> }
    token tag:sym<$*|>  { <sym> <tag-name> }
    token tag:sym<$**>  { <sym> <tag-name> }
    token tag:sym<$>    { <sym> <tag-name> }

    token mod-name      { <.identifier> }
    token meth-name     { <.identifier> }
    token tag-name      { [ <namespace> ':' ]? <element> }
    token element       { <.identifier> }
    token namespace     { <.identifier> }

#`{{
#    token reset-keep-literal { <?> }
#    token tag { <.reset-keep-literal> <.tag-name> ( <.attribute> )* }
    token tag { <.tag-name> <.attributes> }
    token tag-name { <.tag-type> <.identifier> [ ':' <.identifier> ]**0..1 }
    token tag-type {
      ( '$.' <.identifier> '.' ) ||
      ( '$!' <.identifier> '.' ) ||
      '$*<' || '$*>' || '$*'     ||
      '$'
    }
}}
    # The tag may be followed by attributes. These are key=value constructs. The
    # key is an identifier and the value can be anything. Enclose the value in
    # quotes ' or " when there are whitespace characters in the value.
    #
    token attributes    { [<.ws>? <attribute>]* }
    token attribute     { <attr-key> '=' <attr-value-spec> }
    token attr-key      { [<key-ns> ':' ]? <key-name> }
    token key-ns        { <.identifier> }
    token key-name      { <.identifier> }
    token attr-value-spec {
      [\' $<attr-value>=<.attr-q-value> \']  ||
      [\" $<attr-value>=<.attr-qq-value> \"] ||
      $<attr-value>=<.attr-s-value>
    }
    token attr-q-value  { <-[\']>+ }
    token attr-qq-value { <-[\"]>+ }
    token attr-s-value  { <-[\s]>+ }

    # The tag body is anything enclosed in [...], [=...] or [-...]. The first
    # situation is the normal one of which all spaces will be reduced to one
    # space and leading and trailing spaces are removed. The second form is
    # used to save spacing as is. The third will not accept any child elements
    # so the $ sign is free to use without escaping it. Useful to insert
    # javascript code. ] and # still needs to be escaped when needed. To keep the
    # content of [- ...] also as is written write [+ ...].
    #
    # Changed from rule into token because of body character '[' followed up with
    # optional '+', '-' and '=' may not be separated by a space. Then content
    # starting with a those characters doesn't have to be escaped when they are
    # used. Just use a space in front. Can happen in tables showing numbers.
    #
#`{{
    token tag-body {
      <ws>?
      (  <.body2-start> ~ <.body2-end> <.body2-contents>     # Only text content
      || <.body1-start> ~ <.body1-end> <.body1-contents>     # Normal body content
      )
#      <comment>*
    }
}}
    token tag-body {
      <ws>?
      [ '[!=' ~ '!]'    <body1-contents>) ||
        '[!' ~ '!]'     <body2-contents>) ||
        '[=' ~ ']'      <body3-contents>) ||
        '[' ~ ']'       <body4-contents>)
      ]
      <ws>?
    }

    # The content can be anything mixed with document tags except following the
    # no-elements character. To use the brackets and
    # other characters in the text, the characters must be escaped.
    #
    rule body1-contents  { <.body2-text> }
    rule body2-contents  { <.body2-text> }
    rule body3-contents  { [ <.body1-text> || <.document> ]* }
    rule body4-contents  { [ <.body1-text> || <.document> ]* }

#    rule body1-contents  { <.keep-literal>? ( <.body1-text> || <.document> )* }
#    token body1-start     { '[' }
#    token body1-end       { ']' }
#    token body1-text      { ( <.comment> || <-[\$\]\\]> || <.body-esc> )+ }
    token body1-text      { ( <-[\$\]\\]> || <.body-esc> )+ }

#    rule body2-contents  { <.keep-literal>? <.body2-text> }
#    token body2-start     { '[!' }
#    token body2-end       { '!]' }
    token body2-text      { .*? <?before '!]'> }

#    token keep-literal    { '=' }
    token body-esc        { '\\' . }

#    token comment         { \n? \s* '#' <-[\n]>* \n }

    # See STD.pm6 of perl6. A tenee bit simplefied. .ident is precooked and a
    # dash within the string is accepted.
    #
    token identifier { <.ident> [ '-' <.ident> ]* }
  }
}
