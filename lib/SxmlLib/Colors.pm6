use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<https://github.com/MARTIMM>;

use SemiXML::StringList;
use SxmlLib::SxmlHelper;
use XML;
use Color;
use Color::Operators;

#-------------------------------------------------------------------------------
# Core module with common used methods
class Colors {

  #-----------------------------------------------------------------------------
  # $!Colors.colors base-rgb=<color> generates
  # <sxml:variable name=xyz>color</sxml:variable> variables where xyz becomes
  # one of base-color, ....
  # The namespace xmlns:sxml="github:MARTIMM" is placed on top level element
  # and removed later when document is ready.
  # See also http://scholarship.claremont.edu/cgi/viewcontent.cgi?article=1881&context=cmc_theses
  method palette (
    XML::Element $parent, Hash $attrs, XML::Node :$content-body
    --> XML::Node
  ) {

    my List $xc;
    my Color $base-color;
    my Bool $use-alpha = False;

    if ? ~$attrs<base-rgb> {
      $xc = ($attrs<base-rgb>:delete).List;
note "RGB: $xc.perl()";
      if $xc[0] ~~ /'#' [<xdigit>**3 || <xdigit>**6]/ {
        $base-color .= new($xc[0]);
        if ? $xc[1] {
          $base-color .= new(:rgba([ |$base-color.rgb, $xc[1]]));
          $use-alpha = True;
        }
      }

      elsif $xc.elems >= 3 {
        $base-color .= new(:rgb([|$xc[0..2]]));
        if ? $xc[3] {
          $base-color .= new(:rgba([ |$base-color.rgb, $xc[3]]));
          $use-alpha = True;
        }
      }

      else {
        die "Note the proper number of color elements. Use '#xxx[,op]', '#xxxxxx[,op]' or 'r,g,b[,op]'";
      }
    }

    elsif ? ~$attrs<base-hsl> {
      $xc = ($attrs<base-hsl>:delete).List;
note "HSL: $xc.perl()";
      $base-color .= new(:hsl([|$xc[0..2]]));
      if ? $xc[3] {
        $base-color .= new(:rgba([ |$base-color.rgb, $xc[3]]));
        $use-alpha = True;
      }
    }

    else {
note "X: $attrs.perl()";
    }

#    my Color $base-color .= new(~$attrs<base-rgb>);

    my Hash $color-set;
    given ~$attrs<type> {
      when 'averaged' {
        $color-set = self!averaged-colors($base-color);
      }

      when 'blended' {
        $color-set = self!blended-colors( $base-color, ~$attrs<mode>);
      }

      default {
        $color-set = self!averaged-colors($base-color);
      }
    }

    my $bce = append-element( $parent, 'sxml:variable', %(:name<base-color>));
    append-element( $bce, :text($base-color.to-string('hex')));

    for $color-set.kv -> $name, $color {
      my $e = append-element( $parent, 'sxml:variable', %(:$name));
      append-element( $e, :text($color.to-string('hex')));
    }

    $parent;
  }

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
  method !averaged-colors ( Color $base --> Hash ) {

    my Hash $d = {};

    $d<color-one> = self!random-color($base);
    $d<color-two> = self!random-color($base);
    $d<color-three> = self!random-color($base);
    $d<color-four> = self!random-color($base);
    $d<color-five> = self!random-color($base);

    $d
  }

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
  method !hard-light-blend ( Color $cb, Color $cs --> Color ) {
    #my Array $rgbad-b = [$cb.rgbad];
    #my Array $rgbad-s = [$cs.rgbad];

    my Color $cr = ([+] $cs.rgbd)/3.0 <= 0.5
        ?? self!multiply-blend( $cb, Color.new(:rgbd((2,2,2) Z* $cs.rgbd)))
        !! self!screen-blend(
             $cb,
             Color.new(:rgbd( ((2,2,2) Z* $cs.rgbd ) Z- (1, 1, 1)))
           )
    ;
  }

  #-----------------------------------------------------------------------------
  # blend
  method !blend ( Color $cb, Color $cs, Str $mode --> Color ) {

    given $mode {
      when 'multiply' {
        self!multiply-blend( $cb, $cs)
      }

      when 'screen' {
        self!screen-blend( $cb, $cs)
      }

      when 'overlay' {
        self!hard-light-blend( $cb, $cs)
      }

      default {
      }
    }
  }

  #-----------------------------------------------------------------------------
  # blended color
  method !blended-color ( Color $base, Str $mode --> Color ) {

    my Array $base-rgb = [$base.rgba];

    # calculate random backdrop color
    my Int $red = 256.rand.Int;
    my Int $green = 256.rand.Int;
    my Int $blue = 256.rand.Int;

    # backdrop color has opacity of 0.1
    0.9 * $base + 0.1 * self!blend(
      Color.new( $red, $green, $blue), $base, $mode
    );
  }

  #-----------------------------------------------------------------------------
  # blended colors
  method !blended-colors ( Color $base, Str $mode --> Hash ) {
note "C&B: $base.to-string('hex'), $mode";

    my Hash $d = {};

    $d<color-one> = self!blended-color( $base, $mode);
    $d<color-two> = self!blended-color( $base, $mode);
    $d<color-three> = self!blended-color( $base, $mode);
    $d<color-four> = self!blended-color( $base, $mode);
    $d<color-five> = self!blended-color( $base, $mode);

    $d
  }
}
