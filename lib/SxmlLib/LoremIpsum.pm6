use v6.c;

use Semi-xml;
#use XML;

# Not yet available for perl 6
#use Text::Lorem;

# Package cannot be placed in Semi-xml/Lib and named File.pm6. Evaluation seems
# to fail not finding the symbol &File when doing so.
#
package SxmlLib:auth<https://github.com/MARTIMM> {

  class LoremIpsum {
    has Hash $.symbols = {};

    #---------------------------------------------------------------------------
    #
    method show ( XML::Element $parent,
                  Hash $attrs,
                  XML::Node :$content-body   # Ignored
                ) {

      my $type = $attrs<type> // 'sentence';
      my $size = $attrs<size> // 1;
      my $ipsum;
      
      if $type eq 'standard-1500' {
        $ipsum = Q:to/EOIPSUM/;
          Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
          eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim
          ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut
          aliquip ex ea commodo consequat. Duis aute irure dolor in
          reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
          pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
          culpa qui officia deserunt mollit anim id est laborum.
          EOIPSUM
      }
      
      elsif $type eq 'Cicero-45BC-1.10.32' {
        $ipsum = Q:to/EOIPSUM/;
          Sed ut perspiciatis unde omnis iste natus error sit voluptatem
          accusantium doloremque laudantium, totam rem aperiam, eaque ipsa
          quae ab illo inventore veritatis et quasi architecto beatae vitae
          dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit
          aspernatur aut odit aut fugit, sed quia consequuntur magni dolores
          eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam
          est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci
          velit, sed quia non numquam eius modi tempora incidunt ut labore et
          dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam,
          quis nostrum exercitationem ullam corporis suscipit laboriosam,
          nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure
          reprehenderit qui in ea voluptate velit esse quam nihil molestiae
          consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla
          pariatur?
          EOIPSUM
      }
      
      elsif $type eq 'Cicero-45BC-1.10.33' {
        $ipsum = Q:to/EOIPSUM/;
          Sed ut perspiciatis unde omnis iste natus error sit voluptatem
          accusantium doloremque laudantium, totam rem aperiam, eaque ipsa
          quae ab illo inventore veritatis et quasi architecto beatae vitae
          dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit
          aspernatur aut odit aut fugit, sed quia consequuntur magni dolores
          eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est,
          qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit,
          sed quia non numquam eius modi tempora incidunt ut labore et dolore
          magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis
          nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut
          aliquid ex ea commodi consequatur? Quis autem vel eum iure
          reprehenderit qui in ea voluptate velit esse quam nihil molestiae
          consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla
          pariatur?
          EOIPSUM
      }

      elsif $type eq 'paragraphs' {
#        my $tl = Text::Lorem->new;
#        $ipsum = $tl->paragraphs($size);
        $ipsum = "Paragraphs not yet implemented";
      }

      elsif $type eq 'sentences' {
#        my $tl = Text::Lorem->new;
#        $ipsum = $tl->sentences($size);
        $ipsum = "Sentences not yet implemented";
      }

      elsif $type eq 'words' {
#        my $tl = Text::Lorem->new;
#        $ipsum = $tl->words($size);
        $ipsum = "Words not yet implemented";
      }

      elsif $type eq 'cupcake-ipsum' {
        $ipsum = Q:to/EOIPSUM/;
          Cupcake ipsum dolor sit. Amet I love liquorice jujubes pudding
          croissant I love pudding. Apple pie macaroon toffee jujubes pie tart
          cookie applicake caramels. Halvah macaroon I love lollipop. Wypas I
          love pudding brownie cheesecake tart jelly-o. Bear claw cookie
          chocolate bar jujubes toffee.
          EOIPSUM
      }

      elsif $type eq 'samuel-l-ipsum' {
        $ipsum = Q:to/EOIPSUM/;
          Now that there is the Tec-9, a crappy spray gun from South Miami.
          This gun is advertised as the most popular gun in American crime. Do
          you believe that shit? It actually says that in the little book that
          comes with it: the most popular gun in American crime. Like they're
          actually proud of that shit.
          EOIPSUM
      }

      elsif $type eq 'bacon-ipsum' {
        $ipsum = Q:to/EOIPSUM/;
          Bacon ipsum dolor sit amet salami jowl corned beef, andouille flank
          tongue ball tip kielbasa pastrami tri-tip meatloaf short loin beef
          biltong. Cow bresaola ground round strip steak fatback meatball
          shoulder leberkas pastrami sausage corned beef t-bone pork belly
          drumstick.
          EOIPSUM
      }

      elsif $type eq 'tuna-ipsum' {
        $ipsum = Q:to/EOIPSUM/;
          Moonfish, steelhead, lamprey southern flounder tadpole fish sculpin
          bigeye, blue-redstripe danio collared dogfish. Smalleye squaretail
          goldfish arowana butterflyfish pipefish wolf-herring jewel tetra,
          shiner; gibberfish red velvetfish. Thornyhead yellowfin pike
          threadsail ayu cutlassfish.
          EOIPSUM
      }

      elsif $type eq 'veggie-ipsum' {
        $ipsum = Q:to/EOIPSUM/;
          Veggies sunt bona vobis, proinde vos postulo esse magis grape pea
          sprouts horseradish courgette maize spinach prairie turnip jicama
          coriander quandong gourd broccoli seakale gumbo. Parsley corn
          lentil zucchini radicchio maize horseradish courgette maize spinach
          prairie turnip j\N{U+00ED}cama coriander quandong burdock avocado
          sea lettuce. Garbanzo tigernut earthnut pea fennel.
          EOIPSUM
      }

      elsif $type eq 'cheese-ipsum' {
        $ipsum = Q:to/EOIPSUM/;
          I love cheese, especially airedale queso. Cheese and biscuits
          halloumi cauliflower cheese cottage cheese swiss boursin fondue
          caerphilly. Cow port-salut camembert de normandie macaroni cheese
          feta who moved my cheese babybel boursin. Red leicester roquefort
          boursin squirty cheese jarlsberg blue castello caerphilly chalk
          and cheese. Lancashire.
          EOIPSUM
      }
      
      else {
        $ipsum = "Type $type not supported";
      }

      $parent.append(XML::Text.new(:text($ipsum)));
    }
  }
}

