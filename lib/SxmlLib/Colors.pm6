use v6;

#-------------------------------------------------------------------------------
# http://www.paletton.com/wiki/index.php?title=Welcome_to_the_Colorpedia
# http://scholarship.claremont.edu/cgi/viewcontent.cgi?article=1881&context=cmc_theses
# http://www.malanenewman.com/color_theory_color_wheel.html

unit package SxmlLib:auth<github:MARTIMM>;

use SemiXML::StringList;
use SemiXML::Element;
#use XML;
use Color;
use Color::Operators;

#-------------------------------------------------------------------------------
class Colors {

  has Bool $!use-alpha = False;

  #-----------------------------------------------------------------------------
  # $!Colors.colors base-rgb=<color> generates
  # <sxml:var-decl name=xyz>color</sxml:var-decl> variables where xyz becomes
  # one of base-color, ....
  # The namespace xmlns:sxml="github:MARTIMM" is placed on top level element
  # and removed later when document is ready.

  method palette ( SemiXML::Element $m --> Array ) {

    my List $xc;
    my Color $base-color;
    $!use-alpha = False;

    # find out what color scheme is used
    # base color given in rgb
    if $m.attributes<base-rgb>:exists {

      # if base-rgb it can be defined in 4 different ways
      $xc = ($m.attributes<base-rgb>:delete).List;
#note "RGB: $xc.perl()";
      # as '#xxx', '#xxxxxx', '('#xxx d', '#xxxxxx d'
      if $xc[0] ~~ /^ '#' [<xdigit>**3 || <xdigit>**6] $/ {
        $base-color .= new($xc[0]);
        if ? $xc[1] {
          $base-color .= new(:rgba([ |$base-color.rgb, $xc[1].UInt]));
          $!use-alpha = True;
        }
      }

      # as '#xxxxxxxx'
      elsif $xc[0] ~~ /^ '#' <xdigit>**8 $/ {
#note "8 digits rgb";
        $base-color .= new($xc[0]);
        $!use-alpha = True;
      }

      # as 'd d d', 'd d d d'
      elsif $xc.elems >= 3 {
        $base-color .= new(:rgb([|$xc[0..2]>>.Real]));
        if ? $xc[3] {
          $base-color .= new(:rgba([ |$base-color.rgb, $xc[3].UInt]));
          $!use-alpha = True;
        }
      }

      else {
        die "Not a proper rgb spec";
      }
    }

    # base color given in hsl
    elsif $m.attributes<base-hsl>:exists {

      # if base-hsl it can be defined in 2 different ways
      $xc = ($m.attributes<base-hsl>:delete).List;
#note "HSL: $xc.perl()";
      # as 'd d d' or 'd d d d'
      $base-color .= new(:hsl([|$xc[0..2]>>.Real]));
      if ? $xc[3] {
        $base-color .= new(:rgba([ |$base-color.rgb, $xc[3]]));
        $!use-alpha = True;
      }
    }

    else {
note "X: $m.attributes.perl()";
      die "Not a defined color type, attributes found are: $m.attributes.keys().join(', ')";
    }

    # hash to set the colors in
    # The blended type operations set color1, color2, ...
    # The monochromatic type set primary-color1, primary-color2, ...
    my Seq $color-set;

    # get number of colors to generate
    my UInt $ncolors = ($m.attributes<ncolors>//5).Str.UInt;

    # the default type is color-scheme.
    my Str $type = ($m.attributes<type>//'color-scheme').Str;

    my Str $oper-name = '';

    # do the operations according to its type.
    given $type {

      when 'blended' {
        $oper-name = 'blend';
        $color-set = self!blended-colors( $base-color, $ncolors, $m.attributes);
      }

      when 'color-scheme' {
        $oper-name = 'scheme';
        $color-set = self!color-scheme( $base-color, $ncolors, $m.attributes);
      }
    }

    # get the set name and color name for the variables
    my Str $set-name = ($m.attributes<set-name>//'').Str;
    my Str $color-name = ($m.attributes<color-name>//'color').Str;

    my Str $output-spec = ($m.attributes<outspec>//'rgbhex').Str;

    # create a variable for the base color
    my Array $element-array = [];

    my SemiXML::Element $bce .= new(
      :name<sxml:var-decl>, :attributes({:name<base-color>})
    );
    $bce.body-type = SemiXML::BodyC;
    $bce.append(:text(self!output-spec( $base-color, $output-spec)));
    $element-array.push: $bce;

    # create a variable for each color
    my Int $color-count = 1;
    for @$color-set -> $color {
      my Str $name = [~] (?$set-name ?? "$set-name-" !! ''),
                     $oper-name, '-', $color-name, $color-count++;

#TODO is $e[text], $e{text} or $e«text» possible?
#     or $e« A, text»
      my SemiXML::Element $e .= new(
        :name<sxml:var-decl>, :attributes({:$name,:noconv})
      );

      my SemiXML::Text $t .= new(
        :text(self!output-spec( $color, $output-spec))
      );

      $t.body-type = SemiXML::BodyC;
      $e.append($t);
      $element-array.push: $e;
    }

    $element-array
  }

  #-----------------------------------------------------------------------------
  method !output-spec ( Color $color, Str $output-spec --> Str ) {

    my Str $color-spec;
    if $output-spec eq 'rgb' {
      my @c = $color.rgbad;
      if $!use-alpha {
        $color-spec =
          [~] 'rgba(',
          (map {($_ * 100).fmt('%.1f') ~ '%'}, @c).join(','),
          ')';
      }

      else {
        $color-spec =
          [~] 'rgb(',
          (map {($_ * 100).fmt('%.1f') ~ '%'}, @c[0..2]).join(','),
          ')';
      }
    }

    elsif $output-spec eq 'rgbhex' {
      if $!use-alpha {
        $color-spec = $color.to-string('hex8');
      }

      else {
        $color-spec = $color.to-string('hex');
      }
    }

    elsif $output-spec eq 'hsl' {
      if $!use-alpha {
        my $alpha = $color.rgbad[3];
        $color-spec =
          [~] 'hsla(',
          (map {$_.fmt('%.1f') ~ '%'}, (|$color.hsl,$alpha)).join(','),
          ')';
        # remove the first and last percent again
        $color-spec ~~ s/ '%' //;
        $color-spec ~~ s/ '%)' /)/;
      }

      else {
        $color-spec =
          [~] 'hsla(',
          (map {$_.fmt('%.1f') ~ '%'}, $color.hsl).join(','),
          ')';
        # remove the first percent again
        $color-spec ~~ s/ '%' //;
      }

#note "Color: $color-spec";
      $color-spec
    }
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

    # calculate random backdrop color
    my Color $rc .= new(:rgbad([|(rand xx 3), 1]));

    # backdrop color is the inverted opacity
    $opacity * $base + (1.0 - $opacity) * self!blend( $rc, $base, $mode);
  }

  #-----------------------------------------------------------------------------
  # blended colors
  method !blended-colors ( Color $base, UInt $ncolors, Hash $attrs --> Seq ) {

    my Str $mode = ($attrs<mode>//'multiply').Str;
    my Num $opacity = ($attrs<opacity>//0.9).Str.Num;

    $opacity = 0e0 if $opacity < 0e0;
    $opacity = 1e0 if $opacity > 1e0;
#note "BC: $base.to-string('hex8'), $mode, $opacity";

    my Array $ca = [ self!blended-color( $base, $mode, $opacity) xx $ncolors];

#note "CA: $ca.elems()";
    $ca.sort({ ([+] $^a.rgbad) <=> ([+] $^b.rgbad) })
  }

  #-----------------------------------------------------------------------------
  # color schemas
  method !color-scheme ( Color $base, UInt $ncolors, Hash $attrs --> Seq ) {

    my Str $mode = ($attrs<mode>//'monochromatic').Str;
    my Real $lighten = ($attrs<lighten>//0.0).Str.Real;
    my Real $saturate = ($attrs<saturate>//0.0).Str.Real;
#note "M0: $base.to-string('hex8'), $mode, $lighten, $saturate";

    # get color in hsl form where this color is the center color
    my @c = $base.hsl;

    my Array $ca = [];
    given $mode {
      when 'monochromatic' {
        my Real $step = ($ncolors - 1) / 2.0;
        my Real $start-s = @c[1] - $step * $saturate;
        my Real $start-l = @c[2] - $step * $lighten;
#note "M1: $step, $start-s, $start-l";
        for ^$ncolors -> $n {
          # set default of original color in case of only one is needed
          my $s = @c[1];
          my $l = @c[2];
          if ?$lighten and ?$saturate {
            $s = $start-s + $n * $saturate;
            $l = $start-l + $n * $lighten;
          }

          elsif ?$lighten {
            $l = $start-l + $n * $lighten;
          }

          elsif ?$saturate {
            $s = $start-s + $n * $saturate;
          }

#note "M2: $n, @c[0], $s, $l";
          my Color $c .= new(:hsl( @c[0], $s, $l));
          $ca.push($c);
        }
      }
    }

    $ca.Seq;
  }
}
