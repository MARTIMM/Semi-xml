use v6;

#-------------------------------------------------------------------------------
# Example from w3schools
unit package SxmlLib:auth<github:MARTIMM>;

use XML;
#use SemiXML::Sxml;
use SxmlLib::SxmlHelper;

#-------------------------------------------------------------------------------
class Html::Menu {

  my Bool $menu-js-stored = False;

  #-----------------------------------------------------------------------------
  method container (
    XML::Element $parent,
    Hash $attrs is copy,
    XML::Node :$content-body
  ) {
    my Str $id = ($attrs<id>//'SideNav').Str;
    my Str $class = ($attrs<class>//'sidenav').Str;
    my Str $location = ($attrs<id>//'left').Str;

    self!create-style( $parent, $id, $class);


    my XML::Element $span = append-element(
      $parent, 'span', {
        class => 'menu-open-button',
        onclick => 'menu.openNavigation()'
      }
    );

    append-element( $span, :text('&#9776;'));

    my XML::Element $div = append-element(
      $parent, 'div', {
        id => $id, class => $class,
      }
    );

    my XML::Element $a = append-element(
      $div, 'a', {
        href => 'javascript:void(0)', class => 'menu-close-button',
        onclick => 'menu.closeNavigation()',
      }
    );

    append-element( $a, :text('&#x2716;'));

    self!create-script( $parent, $id);

    $div.append($content-body);
    $parent;
  }

  #-----------------------------------------------------------------------------
  method entry (
    XML::Element $parent,
    Hash $attrs is copy,
    XML::Node :$content-body
  ) {
    my Str $title = ($attrs<title>//'...title...').Str;
    my Str $id = ($attrs<id>//'...id...').Str;

    drop-parent-container($content-body);

    my XML::Element $a = append-element( $parent, 'a', {href => '#'});
    append-element( $a, :text($title));

    my XML::Element $page-div = append-element( $parent, 'div', { id => $id});
note "CB: $content-body";
    $page-div.append(clone-node($_)) for $content-body.nodes;

    $parent;
  }

  #-----------------------------------------------------------------------------
  # create a style element with the properties for a menu
  method !create-style( XML::Element $parent, Str $id, Str $class ) {

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
          left:       0;
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
          openNavigation: function() {
            document.getElementById('$id').style.width = "250px";
          },

          closeNavigation: function() {
            document.getElementById('$id').style.width = "0";
          }
        }
        EOJS

      $menu-js-stored = True;
    }
  }
}
