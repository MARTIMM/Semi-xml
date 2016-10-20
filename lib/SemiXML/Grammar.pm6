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

#`{{
    # The prelude is a series of configuration options looking like
    #
    # /x/y/opt:  value;
    #
    rule prelude { <.config-entry>* }
    rule config-entry {
      <.comment>*
      <.config-keypath> ':' <.config-value> ';'
      <.comment>*
    }

    token config-keypath { <.config-key> ( '/' <.config-key> )* }
    token config-key { <.identifier> }
    rule config-value { <.config-value-esc> || <-[;]>+ }
    token config-value-esc { '\;' }
}}

    # A document is only a tag with its content. Defined like this there can only
    # be one toplevel document.
    #
    token document { <.comment>* <.tag> <.tag-body> <.comment>* }

    # A tag is an identifier prefixed with $. $! or $ to attach several semantics
    # to the tag.
    #
    # $table class=bussiness id=sect1 
    #
    token reset-keep-literal { <?> }
    token tag { <.reset-keep-literal> <.tag-name> ( <.attribute> )* }
    token tag-name { <.tag-type> <.identifier> [ ':' <.identifier> ]**0..1 }
    token tag-type {
      ( '$.' <.identifier> '.' ) ||
      ( '$!' <.identifier> '.' ) ||
      '$*<' || '$*>' || '$*'     ||
      '$'
    }

    # The tag may be followed by attributes. These are key=value constructs. The
    # key is an identifier and the value can be anything. Enclose the value in
    # quotes ' or " when there are whitespace characters in the value.
    # 
    token attribute { <.ws>? <.attr-key> '=' <.attr-value-spec> }
    token attr-key { <.identifier> [ ':' <.identifier> ]**0..1 }
    token attr-value-spec {
      (\' <.attr-q-value> \')  ||
      (\" <.attr-qq-value> \") ||
      <.attr-s-value>
    }
    token attr-q-value    { <-[\']>+ }
    token attr-qq-value   { <-[\"]>+ }
    token attr-s-value    { <-[\s]>+ }

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
    token tag-body {
      <ws>?
      (  <.body2-start> ~ <.body2-end> <.body2-contents>     # Only text content
      || <.body1-start> ~ <.body1-end> <.body1-contents>     # Normal body content
      )
      <comment>*
    }

    # The content can be anything mixed with document tags except following the
    # no-elements character. To use the brackets and
    # other characters in the text, the characters must be escaped.
    #
    token body1-contents  { <.keep-literal>? ( <.body1-text> || <.document> )* }
    token body1-start     { '[' }
    token body1-end       { ']' }
    token body1-text      { ( <.comment> || <-[\$\]\\]> || <.body-esc> )+ }

    token body2-start     { '[!' }
    token body2-contents  { <.keep-literal>? <.body2-text> }
    token body2-text      { .*? <?before '!]'> }
    token body2-end       { '!]' }

    token keep-literal    { '=' }
    token body-esc        { '\\' . }

    token comment         { \n? \s* '#' <-[\n]>* \n }

    # See STD.pm6 of perl6. A tenee bit simplefied. .ident is precooked and a
    # dash within the string is accepted.
    #
    token identifier { <.ident> [ '-' <.ident> ]* }
  }
}
