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
      my Str $style-pivot-id = ($m.attributes<style-pivot-id> // '').Str;
      my Str $oper = ($m.attributes<insert-style> // '').Str;
      $oper = 'after' unless $oper ~~ any(<before after>);

      # try to find style and insert after that one
      if ?$style-pivot-id {
        # place style after given id or last one if not found
        for @$r -> $style-node {
          if ($style-node.attributes<id>//'--').Str eq $style-pivot-id {
            $style-node."$oper"($!style);
            last;
          }
        }
      }

      # no attribute used so insert after the last style element
      else {
        $r[*-1]."$oper"($!style);
      }
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

    # the script element should go to the end but must look for id's
    # to place the element carefully. search in the body for scripts first.
    $!script .= new(
      :name<script>, :attributes({'sxml:noconv' => '1'}), :text("\n")
    );

    $!style.noconv = True;
    $r = $m.search( [
        SemiXML::SCRoot, 'html', SemiXML::SCChild, 'body',
        SemiXML::SCChild, 'script'
      ]
    );

    if $r.elems {
      my Str $script-pivot-id = ($m.attributes<script-pivot-id> // '').Str;
      my Str $oper = ($m.attributes<insert-script> // '').Str;
      $oper = 'after' unless $oper ~~ any(<before after>);

      # try to find script and insert after that one
      if ?$script-pivot-id {
        # place style after given id or last one if not found
        for @$r -> $script-node {
          if ($script-node.attributes<id>//'--').Str eq $script-pivot-id {
            $script-node."$oper"($!script);
            last;
          }
        }
      }

      # no attribute used so insert after the last style element
      else {
        $r[*-1]."$oper"($!script);
      }
    }

    # no style found add to the end of head
    else {
      $r = $m.search( [ SemiXML::SCRoot, 'html', SemiXML::SCChild, 'body']);
      if $r.elems {
        $r[0].append($!script);
      }

      else {
        die 'Script must be placed in /html/body but body is not found';
      }
    }

    $!initialized = True;
  }

  #-----------------------------------------------------------------------------
  method container ( SemiXML::Element $m ) {

#note "\nContainer";
    my Str $id = ($m.attributes<id>//'SideNav').Str;
    my Str $class = ($m.attributes<class>//'sidenav').Str;
    my Str $side = ($m.attributes<side>//'').Str;
    $side = 'left' unless $side ~~ any( 'left', 'right');

    # style element and their setting for the menu and pages
    self!create-style( $m, $id, $class, $side);
    self!create-script( $m, $id);

    my SemiXML::Element $side-nav .= new(
      :name<div>, :attributes( { :$id, :$class})
    );
    $m.before($side-nav);

    # insert a hook element to insert the pages after
    my SemiXML::Element $hook = $m.after('sxml:hook');

    for $m.nodes.reverse -> $node {
#note "Node: $node.name(), ", $node.attributes.keys;
      if $node ~~ SemiXML::Element and $node.name eq 'a' {
        $side-nav.insert($node);
      }

      elsif $node ~~ SemiXML::Element and $node.name eq 'div' {
        $hook.after($node);
      }
    }

    $side-nav.append(
      'a',
      :attributes( {
          href => 'javascript:void(0)',
          class => 'menu-close-button',
          onclick => 'menu.closeNavigation()',
        }
      ),
      :text('&#x2716;')
    );

    # run through the page divs again and toggle the first page from
    # display:none to display:block to make the first one visible
    for $!script.parent.nodes -> $node {
      if $node ~~ SemiXML::Element and $node.name eq 'div' {
        if $node.attributes<class>:exists and
           $node.attributes<class> eq 'menu-page' {

          $node.attributes( {:style('display: block;')}, :modify);
          last;
        }
      }
    }

    # remove hook
    $hook.remove;

    # prepare for next setup, although it will not work (yet) if at all logical
    $!initialized = False;
  }

  #-----------------------------------------------------------------------------
  method entry ( SemiXML::Element $m ) {

#note "\nEntry: $m.name(), ", $m.attributes.keys;

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
          class => 'menu-entry'
        }
      ),
      :text($title)
    );

    my SemiXML::Element $page-div = $m.before(
      'div',
      :attributes( { :$id, :style('display: none'), :class('menu-page')})
    );

    $page-div.insert($_) for $m.nodes.reverse;

    if $open-button {
      $page-div.insert(
        'a',
        :attributes( {
            href => 'javascript:void(0)',
            class => 'menu-open-button',
            onclick => 'menu.openNavigation()',
            title => 'Open menu'
          }
        ),
        :text('&#9776;')
      );
    }

    if $home-button {
      $page-div.insert(
        'a',
        :attributes( {
            href => 'javascript:void(0)',
            class => 'menu-home-button',
            onclick => Q:s "menu.showPage('$main-page-id')",
            title => 'Home page'
          }
        ),
        :text('&#x1F3E0;')
      );
    }
  }

  #-----------------------------------------------------------------------------
  # create a style element with the properties for a menu
  method !create-style( SemiXML::Element $m, Str $id, Str $class, Str $side ) {

    $!style.attributes( {:id($class ~ '-menu-style')}, :modify);
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
          top: 5px;
          left: 5px;
          font-size: 36px;
          padding-left: 10px;
          border: 2px solid black;
          border-radius: 6px;
          width: 40px;
          height: 40px;
      }

      .$class .menu-entry {
          border: 2px solid black;
          border-radius: 6px;
          padding-left: 5px;
          margin: 0 5px 2px 5px;
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
