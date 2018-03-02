use v6;

#-------------------------------------------------------------------------------
# Example from w3schools
unit package SxmlLib:auth<github:MARTIMM>;

use SemiXML::Element;

#-------------------------------------------------------------------------------
class Html::Menu {

  my Bool $menu-js-stored = False;
  my Str $main-page-id;

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

    self!create-script( $parent, $id);

    my XML::Element $pages-hook = append-element( $parent, 'sxml:hook');
    drop-parent-container($content-body);

    for $content-body.nodes.reverse -> $node {
      if $node ~~ XML::Element and $node.name eq 'a' {
        $menu-div.insert($node);
      }

      elsif $node ~~ XML::Element and $node.name eq 'div' {
        $pages-hook.after($node);
      }
    }

    my XML::Element $a = append-element(
      $menu-div, 'a', {
        href => 'javascript:void(0)',
        class => 'menu-close-button',
        onclick => 'menu.closeNavigation()',
      }
    );

    append-element( $a, :text('&#x2716;'));

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
  }

  #-----------------------------------------------------------------------------
  method entry (
    XML::Element $parent,
    Hash $m.attributes is copy,
    XML::Node :$content-body
  ) {
    my Str $title = ($m.attributes<title>//'...title...').Str;
    my Str $id = ($m.attributes<id>//'...id...').Str;
    my Bool $open-button = ($m.attributes<open-button>//1).Int.Bool;
    my Bool $home-button = ($m.attributes<home-button>//1).Int.Bool;

    # $main-page-id is set to the id of the current entry and it is
    # global to the class.
    $main-page-id //= $id;

    drop-parent-container($content-body);

    # make a link with an empty reference and an onclick function which must
    # show the selected page.
    my XML::Element $a = append-element(
      $parent, 'a', {
        href => 'javascript:void(0)',
        onclick => Q:s "menu.showPage('$id')",
      }
    );
    append-element( $a, :text($title));

    my XML::Element $page-div = append-element(
      $parent, 'div', {
        id => $id,
        style => 'display: none',
        class => 'menu-page'
      }
    );

    $page-div.insert($_) for $content-body.nodes.reverse;

    if $open-button {
      my XML::Element $open-a = insert-element(
        $page-div, 'a', {
          href => 'javascript:void(0)',
          class => 'menu-open-button',
          onclick => 'menu.openNavigation()'
        }
      );

      append-element( $open-a, :text('&#9776;'));
    }

    if $home-button {
      my XML::Element $home-a = insert-element(
        $page-div, 'a', {
          href => 'javascript:void(0)',
          class => 'menu-home-button',
          onclick => Q:s "menu.showPage('$main-page-id')"
        }
      );

      append-element( $home-a, :text('&#x1F3E0;'));
    }

    $parent;
  }

  #-----------------------------------------------------------------------------
  # create a style element with the properties for a menu
  method !create-style( XML::Element $parent, Str $id, Str $class, Str $side ) {

    # map the contents to the end of /html/head
    my XML::Element $remap-style = append-element(
      $parent, 'sxml:remap', { map-to => "/html/head",}
    );

    my XML::Element $style = append-element( $remap-style, 'style');
    append-element( $style, :text(Q:s:to/EOSTYLE/));
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
  method !create-script ( $parent, $id ) {

    if !$menu-js-stored {
      my XML::Element $remap-js = append-element(
        $parent, 'sxml:remap', { map-to => "/html/body",}
      );

      my XML::Element $script = append-element( $remap-js, 'script');
      append-element( $script, :text(Q:s:to/EOJS/));
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
