use v6;

#-------------------------------------------------------------------------------
# Example from w3schools
unit package SxmlLib:auth<github:MARTIMM>;

use SemiXML::Element;

#-------------------------------------------------------------------------------
class Html::Menu {

  my Bool $menu-js-stored = False;
  my Str $main-page-id;

  has SemiXML::Element $!style;
  has SemiXML::Element $!body;
  has SemiXML::Element $!script;
  has Bool $!initialized = False;

  #-----------------------------------------------------------------------------
  method initialize ( SemiXML::Element $m ) {

    return if $!initialized;

    $!style .= new(
      :name<style>, :attributes({'sxml:noconv' => '1'}), :text("\n")
    );
    $!style.noconv = True;

    my Array $r = $m.search( [
        SemiXML::SCRoot, 'html', SemiXML::SCChild, 'head',
        SemiXML::SCChild, 'style'
      ]
    );

    if $r.elems {
      # place style after the last one
      $r[*-1].after($!style);
    }

    # no style found add to the end of head
    else {
      $r = $m.search( [ SemiXML::SCRoot, 'html', SemiXML::SCChild, 'head']);
      if $r.elems {
        $r[0].append($!style);
      }

      else {
        die 'Css must be placed in /html/head but head is not found';
      }
    }

    $r = $m.search( [ SemiXML::SCRoot, 'html', SemiXML::SCChild, 'body']);
    if $r.elems > 0 {
      $!body = $r[0];
    }

    else {
      die 'A body element is not found';
    }

    $!initialized = True;
  }

  #-----------------------------------------------------------------------------
  method container ( SemiXML::Element $m ) {

    my Str $id = ($m.attributes<id>//'SideNav').Str;
    my Str $class = ($m.attributes<class>//'sidenav').Str;
    my Str $side = ($m.attributes<side>//'').Str;
    $side = 'left' unless $side ~~ any( 'left', 'right');

    # style element and their setting for the menu and pages
    self!create-style( $m, $id, $class, $side);

    my SemiXML::Element $menu-div .= new(
      :name<div>, :attributes( { :$id, :$class})
    );
    $m.before($menu-div);

    self!create-script( $m, $id);

    for $m.nodes.reverse -> $node {
note "Node: $node.name(), ", $node.attributes.keys;
      if $node ~~ SemiXML::Element and $node.name eq 'a' {
        $menu-div.insert($node);
      }

      elsif $node ~~ SemiXML::Element and $node.name eq 'div' {
        # The order of the pages are reversed this way but it should not make
        # a difference as long as the pages are referenced properly
        $!script.before($node);

        if $node.attributes<class>:exists
           and $node.attributes<class> eq 'menu-page' {
          $node.attributes({ style => 'display: block;'});
          last;
        }
      }
    }

    $menu-div.append(
      'a',
      :attributes( {
          href => 'javascript:void(0)',
          class => 'menu-close-button',
          onclick => 'menu.closeNavigation()',
        }
      ),
      :text('&#x2716;')
    );

#`{{
    for $parent.nodes -> $node {
      if $node ~~ XML::Element and $node.name eq 'div' {
        if $node.attribs<class>:exists and $node.attribs<class> eq 'menu-page' {
          $node.set( 'style', 'display: block;');
          last;
        }
      }
    }

    $pages-hook.remove;
    $parent;
}}
  }

  #-----------------------------------------------------------------------------
  method entry ( SemiXML::Element $m ) {

note "Entry: $m.name(), ", $m.attributes.keys;

    my Str $title = ($m.attributes<title>//'...title...').Str;
    my Str $id = ($m.attributes<id>//'...id...').Str;
    my Bool $open-button = ($m.attributes<open-button>//1).Int.Bool;
    my Bool $home-button = ($m.attributes<home-button>//1).Int.Bool;

    # $main-page-id is set to the id of the current entry and it is
    # global to the class.
    $main-page-id //= $id;

    # make a link with an empty reference and an onclick function which must
    # show the selected page.
    $m.before(
      'a',
      :attributes( {
          href => 'javascript:void(0)',
          onclick => Q:s "menu.showPage('$id')",
        }
      ),
      :text($title)
    );

    my SemiXML::Element $page-div = $m.before(
      'div',
      :attributes( {
          id => $id,
          style => 'display: none',
          class => 'menu-page'
        }
      )
    );

    $page-div.insert($_) for $m.nodes.reverse;

note "Bttns, $open-button, $home-button";

    if $open-button {
      $page-div.insert(
        'a',
        :attributes( {
            href => 'javascript:void(0)',
            class => 'menu-open-button',
            onclick => 'menu.openNavigation()'
          }
        ),
        :text('&#9776;')
      );
    }

note "X: $page-div";
#return;

    if $home-button {
      $page-div.insert(
        'a',
        :attributes( {
            href => 'javascript:void(0)',
            class => 'menu-home-button',
            onclick => Q:s "menu.showPage('$main-page-id')"
          }
        ),
        :text('&#x1F3E0;')
      );
    }
note "M Parent: ", $m.parent.Str;
  }

  #-----------------------------------------------------------------------------
  # create a style element with the properties for a menu
  method !create-style( SemiXML::Element $m, Str $id, Str $class, Str $side ) {

    $!style.append( :text(Q:s:to/EOSTYLE/));
      /* The side navigation menu */
      .$class {
          height:     100%;               /* 100% Full-height */
          width:      0;                  /* 0 width - change this with JavaScript */
          position:   fixed;              /* Stay in place */
          z-index:    1;                  /* Stay on top */
          top:        0;                  /* Stay at the top */
          $side:      0;
          background-color:   #111;       /* Black*/
          overflow-x:         hidden;     /* Disable horizontal scroll */
          padding-top:        60px;       /* Place content 60px from the top */
          transition:         0.5s;       /* 0.5 second transition effect to slide in the sidenav */
      }

      /* The navigation menu links */
      .$class a {
          padding: 8px 8px 8px 32px;
          text-decoration: none;
          font-size: 25px;
          color: #818181;
          display: block;
          transition: 0.3s;
      }

      /* When you mouse over the navigation links, change their color */
      .$class a:hover {
          color: #f1f1f1;
      }

      /* Position and style the close button (top right corner) */
      .$class .menu-close-button {
          position: absolute;
          top: 0;
          right: 25px;
          font-size: 36px;
          margin-left: 50px;
      }

      /* Position and style the close button (top right corner) */
      .menu-open-button {
        font-size: 30px;
        cursor: pointer;
      }

      .menu-home-button {
        font-size: 30px;
        cursor: pointer;
      }

      /* Style page content - use this if you want to push the page content to the right when you open the side navigation */
      #main {
          transition: margin-left .5s;
          padding: 20px;
      }

      /* On smaller screens, where height is less than 450px, change the style of the sidenav (less padding and a smaller font size) */
      @media screen and (max-height: 450px) {
          .sidenav {padding-top: 15px;}
          .sidenav a {font-size: 18px;}
      }

      EOSTYLE
  }

  #-----------------------------------------------------------------------------
  method !create-script ( $m, $id ) {

    if !$menu-js-stored {
      $!script = $!body.append('script');
      $!script.append(:text(Q:s:to/EOJS/));
        var menu = {
          openNavigation: function ( ) {
            document.getElementById('$id').style.width = "250px";
          },

          closeNavigation: function ( ) {
            document.getElementById('$id').style.width = "0";
          },

          showPage: function ( id ) {
            this.closeNavigation();
            setTimeout(
              function ( ) {

                var node = document.getElementById(id);
                var divNodes = node.parentNode.getElementsByTagName('div');
                for ( var i=0; i < divNodes.length; i++) {
                  if ( divNodes[i].className == 'menu-page' ) {
                    divNodes[i].style.display = "none";
                  }
                }

                document.getElementById(id).style.display = "block";
              },
              750
            );
          }
        }
        EOJS

      $menu-js-stored = True;
    }
  }
}
