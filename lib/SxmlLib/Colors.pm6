use v6;

#-------------------------------------------------------------------------------
# http://www.paletton.com/wiki/index.php?title=Welcome_to_the_Colorpedia
# http://scholarship.claremont.edu/cgi/viewcontent.cgi?article=1881&context=cmc_theses
# http://www.malanenewman.com/color_theory_color_wheel.html

unit package SxmlLib:auth<github:MARTIMM>;

use SemiXML::StringList;
use SxmlLib::SxmlHelper;
use XML;
use Color;
use Color::Operators;

#-------------------------------------------------------------------------------
class Colors {

  #-----------------------------------------------------------------------------
  # $!Colors.colors base-rgb=<color> generates
  # <sxml:variable name=xyz>color</sxml:variable> variables where xyz becomes
  # one of base-color, ....
  # The namespace xmlns:sxml="github:MARTIMM" is placed on top level element
  # and removed later when document is ready.

  method palette (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
    --> XML::Node
  ) {

    my List $xc;
    my Color $base-color;
    my Bool $use-alpha = False;

    # find out what color scheme is used
    # base color given in rgb
    if ? ~$attrs<base-rgb> {

      # if base-rgb it can be defined in 4 different ways
      $xc = ($attrs<base-rgb>:delete).List;
#note "RGB: $xc.perl()";
      # as #xxx, #xxxxxx, (#xxx,d), (#xxxxxx,d)
      if $xc[0] ~~ /'#' [<xdigit>**3 || <xdigit>**6 || <xdigit>**8]/ {
        $base-color .= new($xc[0]);
        if ? $xc[1] {
          $base-color .= new(:rgba([ |$base-color.rgb, $xc[1].UInt]));
          $use-alpha = True;
        }
      }

      # as #xxxxxxxx
      if $xc[0] ~~ /'#' <xdigit>**8/ {
        $base-color .= new($xc[0]);
        $use-alpha = True;
      }

      # as (d,d,d), (d,d,d,d)
      elsif $xc.elems >= 3 {
        $base-color .= new(:rgb([|$xc[0..2]]));
        if ? $xc[3] {
          $base-color .= new(:rgba([ |$base-color.rgb, $xc[3].UInt]));
          $use-alpha = True;
        }
      }

      else {
        die "Note the proper number of color elements. Use '#xxx[,op]', '#xxxxxx[,op]' or 'r,g,b[,op]'";
      }
    }

    # base color given in hsl
    elsif ? ~$attrs<base-hsl> {

      # if base-hsl it can be defined in 2 different ways
      $xc = ($attrs<base-hsl>:delete).List;
note "HSL: $xc.perl()";
      # as (d,d,d) or (d,d,d,d)
      $base-color .= new(:hsl([|$xc[0..2]]));
      if ? $xc[3] {
        $base-color .= new(:rgba([ |$base-color.rgb, $xc[3]]));
        $use-alpha = True;
      }
    }

    else {
note "X: $attrs.perl()";
      die "Not a defined color type, attributes found are: $attrs.keys().join(', ')";
    }

    # hash to set the colors in
    # The blended type operations set color1, color2, ...
    # The monochromatic type set primary-color1, primary-color2, ...
    my Hash $color-set;


    # save some more attribs
    my Str $mode = ($attrs<mode>//'').Str;
    my Str $opacity = ($attrs<opacity>//0.9).Str.Num;
    my Str $ncolors = ($attrs<ncolors>//5).Str.UInt;

    # do the operations according to its type.
    # the default type is monochromatic.
    given ($attrs<type>//'monochromatic').Str {

      when 'blended' {
        $color-set = self!blended-colors(
          $base-color, $mode//'multiply', $opacity, $ncolors
        );
      }

      when 'monochromatic' {
        $color-set = self!monochromatic();

    }


    # create a variable for the base color
    my $bce = append-element( $parent, 'sxml:variable', %(:name<base-color>));
    append-element( $bce, :text($base-color.to-string('hex8')));

    # create a variable for each color
    for $color-set.kv -> $name, $color {
      my $e = append-element( $parent, 'sxml:variable', %(:$name));
      append-element( $e, :text($color.to-string('hex8')));
#note "Color: $name => $color.to-string('hex8'), $e";
    }


    $parent;
  }

#`{{
  #-----------------------------------------------------------------------------
  # private color handling methods
  # random colors
  method !random-color ( Color $base --> Color ) {

    my Array $base-rgb = [$base.rgb];

    my Int $red = ((256.rand.Int + $base-rgb[0])/2).Int;
    my Int $green = ((256.rand.Int + $base-rgb[1])/2).Int;
    my Int $blue = ((256.rand.Int + $base-rgb[2])/2).Int;

    Color.new(:rgb([ $red, $green, $blue]))
  }

  #-----------------------------------------------------------------------------
  # averaged colors
  method !averaged-colors ( Color $base, UInt $ncolors = 5 --> Hash ) {

    my Array $ca = [ self!random-color($base) xx $ncolors];

    my Int $count = 1;
    my Hash $d = {};
    for @$ca.sort({ ([+] $^a.rgbad) <=> ([+] $^b.rgbad) }) -> $c {
      $d{"color" ~ $count++} = $c;
    }

    $d
  }
}}

  #-----------------------------------------------------------------------------
  method !multiply-blend ( Color $cb, Color $cs --> Color ) {
    Color.new(:rgbad([$cb.rgbad Z* $cs.rgbad]))
  }

  #-----------------------------------------------------------------------------
  method !screen-blend ( Color $cb, Color $cs --> Color ) {
    Color.new(
      :rgbad( [
          ($cb.rgbad Z+ $cs.rgbad) Z- ($cb.rgbad Z* $cs.rgbad)
        ]
      )
    )
  }

  #-----------------------------------------------------------------------------
  method !darken-blend ( Color $cb, Color $cs --> Color ) {
    Color.new(:rgbad([ ($cb.rgbad Zmin $cs.rgbad) ]))
  }

  #-----------------------------------------------------------------------------
  method !lighten-blend ( Color $cb, Color $cs --> Color ) {
    Color.new(:rgbad([ ($cb.rgbad Zmax $cs.rgbad) ]))
  }

  #-----------------------------------------------------------------------------
  method !dodge-blend ( Color $cb, Color $cs --> Color ) {

    my Color $c;
    if [+] $cb.rgbad == 0 {
      $c = $cb;
    }

    elsif [+] $cs.rgbad == 1 {
      $c = $cs;
    }

    else {
      $c .= new(
        :rgbad([ (1,1,1,1) Zmin ($cb.rgbad Z/ ((1,1,1,1) Z- $cs.rgbad)) ])
      )
    }

    $c
  }

  #-----------------------------------------------------------------------------
  method !hard-light-blend ( Color $cb, Color $cs --> Color ) {
    ([+] $cs.rgbad)/4.0 <= 0.5
        ?? self!multiply-blend( $cb, Color.new(:rgbad([ (2,2,2,2) Z* $cs.rgbad ])))
        !! self!screen-blend(
             $cb,
             Color.new(:rgbd([ ((2,2,2,2) Z* $cs.rgbd ) Z- (1,1,1,1) ]))
           )
    ;
  }

  #-----------------------------------------------------------------------------
  # blend
  method !blend ( Color $cb, Color $cs, Str $mode --> Color ) {

    my Color $c;
#note "Mode: $mode. $cb.perl(), $cs.perl()";

    given $mode {
      when 'averaged' {
        $c = Color.new(:rgbad([ ($cb.rgbad Z+ $cs.rgbad) Z/ (2,2,2,2) ]));
      }

      when 'multiply' {
        $c = self!multiply-blend( $cb, $cs);
      }

      when 'screen' {
        $c = self!screen-blend( $cb, $cs);
      }

      when 'overlay' {
        my Color $hc = self!hard-light-blend( $cb, $cs);
        $c = Color.new(:rgbad([ (1,1,1,1) Z- $hc.rgbad ]));
      }

      when 'darken' {
        $c = self!darken-blend( $cb, $cs);
      }

      when 'lighten' {
        $c = self!lighten-blend( $cb, $cs);
      }

      when 'dodge' {
        $c = self!dodge-blend( $cb, $cs);
      }

      when 'hard' {
        $c = self!hard-light-blend( $cb, $cs);
      }

#      when 'hard' {
#        $c = self!hard-light-blend( $cb, $cs);
#      }

      default {
        $c .= new(:rgba([ 0, 0, 0, 0]));
      }
    }

    $c
  }

  #-----------------------------------------------------------------------------
  # blended color
  method !blended-color ( Color $base, Str $mode, Num $opacity --> Color ) {

    my Array $base-rgb = [$base.rgba];

    # calculate random backdrop color
    my Color $rc .= new(:rgbad([|(rand xx 3), 1]));

    # backdrop color is the inverted opacity
    $opacity * $base + (1.0 - $opacity) * self!blend( $rc, $base, $mode);
  }

  #-----------------------------------------------------------------------------
  # blended colors
  method !blended-colors (
    Color $base, Str $mode, Num $opacity where 0.0 <= $_ <= 1.0,
    UInt $ncolors = 5
    --> Hash
  ) {
note "C&B: $base.to-string('hex'), $mode, $opacity";

    my Array $ca = [ self!blended-color( $base, $mode, $opacity) xx $ncolors];

    my Int $count = 1;
    my Hash $d = {};
    for @$ca.sort({ ([+] $^a.rgbad) <=> ([+] $^b.rgbad) }) -> $c {
      $d{"color" ~ $count++} = $c;
    }

#note "D: ", $d.perl;
    $d
  }
}
