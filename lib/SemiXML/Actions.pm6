use v6;

#-------------------------------------------------------------------------------
unit package SemiXML:auth<github:MARTIMM>;

use SemiXML;
use SemiXML::Node;
use SemiXML::Element;
use SemiXML::Text;
use SemiXML::StringList;
use XML;

#-------------------------------------------------------------------------------
class Actions {

  has SemiXML::Globals $!globals;

  # the root should only have one element. when there are more, convert
  # the result into a fragment.
  has SemiXML::Element $!root;

  # array of element showing the path to the currently parsed element. therefore
  # an element in the array will always be the parent of the one next to it.
  has Array $!elements;
  has Int $!element-idx;

  has XML::Document $!document;

  #-----------------------------------------------------------------------------
  submethod BUILD ( ) {

    $!globals .= instance;

    # initialize root node and place in the array. this node will never be
    # overwritten.
    $!root .= new(:name<root>);
    $!elements = [$!root];
    $!element-idx = 1;
note "Idx A: $!element-idx";

    #.= new(:name<root>)
  }

  #-----------------------------------------------------------------------------
  method TOP ( $match ) {

note "At the end of parsing";
    for $match.caps -> $pair {

      my $k = $pair.key;
      my $v = $pair.value;
note "  k: $k";
      given $k {
        when 'body-a' {
        }

        #when 'topdocument' {
        when 'document' {
          $!root.append($!elements[1]);
        }
      }
    }



    # see how many elements are stored in root
    # return an empty document
    if $!root.nodes.elems == 0 {
note "No elements";
      my XML::Element $ed .= new(:name<sxml:EmptyDocument>);
      $ed.setNamespace( 'github.MARTIMM', 'sxml');
      $!document .= new($ed);
    }

    # normal xml document
    elsif $!root.nodes.elems == 1 {
note "1 element";
      my XML::Element $root-xml .= new(:name($!root.name));
      $!root.nodes[0].xml($root-xml);
      $!document .= new($root-xml.nodes[0]);
    }

    elsif $!root.nodes.elems > 1 {
note "More elements";
      $!root.node-type = SemiXML::Fragment;

      my XML::Element $root-xml .= new(:name($!root.name));
      $!root.xml($root-xml);
      $!document .= new($root-xml);
    }
  }

  #-----------------------------------------------------------------------------
  method document ( $match ) {

note "\nDocument";
    for $match.caps -> $pair {

      my $k = $pair.key;
      my $v = $pair.value;
#note "  V = $v";

      given $k {
        when 'tag-spec' {
#note "  tag: $v";

          my SemiXML::Element $element;
          for $v.caps -> $vpair {

            my $vk = $vpair.key;
            my $vv = $vpair.value;
            note "  $vk, $vv"
              if $!globals.trace and $!globals.refined-tables<T><parse>;

            given $vk {
              when 'tag' {
                $element = self!create-element($vv);
                $!elements[$!element-idx] = $element;
#                $!elements[$!element-idx - 1].append($!element-idx);
#note "  append $element.name() to $!elements[$!element-idx - 1].name()";

                note "  Created element: ", $element.perl
                  if $!globals.trace and $!globals.refined-tables<T><parse>;
              }

              when 'attributes' {
                $element.attributes(self!attributes([$vv.caps]));
              }
            }
          }

#          $!element-idx++;
#note "Idx B: $!element-idx";
        }

        when 'tag-bodies' {

          for $v.caps -> $vpair {
            my Int $body-count = 0;

            my $vk = $vpair.key;
            my $vv = $vpair.value;
note "  $vk => '$vv'";

            given $vk {
              when 'body-a' {
                my SemiXML::Text $t .= new(:text($vv.Str));
                $t.body-type = SemiXML::BodyA;
                $t.body-number = $body-count;
                $!elements[$!element-idx - 1].append($t);

                note "  append text to", " $!elements[$!element-idx - 1].name()"
                  if $!globals.trace and $!globals.refined-tables<T><parse>;
              }

              when 'body-b' {
                my SemiXML::Text $t .= new(:text($vv.Str));
                $t.body-type = SemiXML::BodyB;
                $t.body-number = $body-count;
                $!elements[$!element-idx - 1].append($t);

                note "  append text to", " $!elements[$!element-idx - 1].name()"
                  if $!globals.trace and $!globals.refined-tables<T><parse>;
              }

              when 'body-c' {
                my SemiXML::Text $t .= new(:text($vv.Str));
                $t.body-type = SemiXML::BodyC;
                $t.body-number = $body-count;
                $!elements[$!element-idx - 1].append($t);

                note "  append text to", " $!elements[$!element-idx - 1].name()"
                  if $!globals.trace and $!globals.refined-tables<T><parse>;
              }

              when 'topdocument' { proceed; }
              when 'document' {

                $!elements[$!element-idx - 2].append(
                  $!elements[$!element-idx - 1]
                );

                note "  append $!elements[$!element-idx - 1].name() to",
                     " $!elements[$!element-idx - 2].name()"
                  if $!globals.trace and $!globals.refined-tables<T><parse>;

              }
            }

            $body-count++;
          }
        }
      }
    }

    $!element-idx--;
note "Idx C: $!element-idx";
  }

  #-----------------------------------------------------------------------------
  method tag-spec ( $match ) {

    note "tag-spec $match"
      if $!globals.trace and $!globals.refined-tables<T><parse>;

    my SemiXML::Element $element;
    for $match.caps -> $pair {

      my $k = $pair.key;
      my $v = $pair.value;
      note "  $k, $v"
        if $!globals.trace and $!globals.refined-tables<T><parse>;

      given $k {
        when 'tag' {
          $element = self!create-element($v);
          $!elements[$!element-idx] = $element;
#          $!elements[$!element-idx - 1].append($element);
#note "  append $element.name() to $!elements[$!element-idx - 1].name()";
        }

#        when 'attributes' {
#          $element.attributes(self!attributes([$v.caps]));
#        }
      }

#      note "  Created element: ", $element.perl
#        if $!globals.trace and $!globals.refined-tables<T><parse>;
    }

    $!element-idx++;
note "Idx B: $!element-idx";

  }

  #-----------------------------------------------------------------------------
  method tag-bodies ( $match ) {
  }

  #-----------------------------------------------------------------------------
  # get the result document
  method get-document ( --> XML::Document ) {

    $!document
  }

  #----[ private stuff ]--------------------------------------------------------
  method !create-element ( $tag --> SemiXML::Element ) {

    my SemiXML::Element $element;

    #my $tag = $match<tag>;

    my Str $symbol = $tag<sym>.Str;
    if $symbol eq '$' {
      $element .= new( :name($tag<tag-name>.Str));
    }

    elsif $symbol eq '$!' {
      $element .= new(
        :module($tag<mod-name>.Str), :method($tag<meth-name>.Str)
      );
    }

    $element
  }

  #-----------------------------------------------------------------------------
  method !attributes ( Array $attr-specs --> Hash ) {

    # define the attributes for the element. attr value is of type StringList
    # where ~$strlst gives string, @$strlst returns list and $strlist.value
    # either string or list depending on :use-as-list which in turn depends
    # on the way an attribute is defined att='val1 val2' or att=<val1 val2>.
    my Hash $attrs = {};
    for @$attr-specs -> $as {
      next unless $as<attribute>:exists;
      my $a = $as<attribute>;
      my SemiXML::StringList $av;

      # when =attr is same as attr=1
      if ? $a<bool-true-attr> {
        $av .= new( :string<1>, :!use-as-list);
      }

      # when =!attr is same as attr=0
      elsif ? $a<bool-false-attr> {
        $av .= new( :string<0>, :!use-as-list);
      }

      else {
        # when attr=<a b c> attr-list-value is set
        $av .= new(
          :string($a<attr-value-spec><attr-value>.Str),
          :use-as-list(?($a<attr-value-spec><attr-list-value> // False))
        );
      }

      $attrs{$a<attr-key>.Str} = $av;
    }

    $attrs;
  }
}
