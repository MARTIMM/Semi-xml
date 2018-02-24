use v6;

#-------------------------------------------------------------------------------
unit package SxmlLib:auth<github:MARTIMM>;

use SemiXML::Element;

#-------------------------------------------------------------------------------
class LoremIpsum {

  # could not use 'has' because of time of existence and calculatig length
  # in submethod BUILD
  #
  my Hash $lorem-texts = {
    perl5-lorem => {
      text => Q:to/EOIPSUM/,
        alias consequatur aut perferendis sit voluptatem accusantium doloremque
        aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto
        beatae vitae dicta sunt explicabo. aspernatur aut odit aut fugit, sed
        quia consequuntur magni dolores eos qui ratione voluptatem sequi
        nesciunt. Neque dolorem ipsum quia dolor sit amet, consectetur, adipisci
        velit, sed quia non numquam eius modi tempora incidunt ut labore et
        dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis
        nostrum exercitationem ullam corporis Nemo enim ipsam voluptatem quia
        voluptas sit suscipit laboriosam, nisi ut aliquid ex ea commodi
        consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate
        velit esse quam nihil molestiae  et iusto odio dignissimos ducimus qui
        blanditiis praesentium laudantium, totam rem voluptatum deleniti atque
        corrupti quos dolores et quas molestias excepturi sint occaecati
        cupiditate non provident, Sed ut perspiciatis unde omnis iste natus
        error similique sunt in culpa qui officia deserunt mollitia animi, id
        est laborum et dolorum fuga. Et harum quidem rerum facilis est et
        expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi
        optio cumque nihil impedit quo porro quisquam est, qui minus id quod
        maxime placeat facere possimus, omnis voluptas assumenda est, omnis
        dolor repellendus. Temporibus autem quibusdam et aut consequatur, vel
        illum qui dolorem eum fugiat quo voluptas nulla pariatur? At vero eos et
        accusamus officiis debitis aut rerum necessitatibus saepe eveniet ut et
        voluptates repudiandae sint et molestiae non recusandae. Itaque earum
        rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus
        maiores doloribus asperiores repellat.
        EOIPSUM
      length => 0,
    }
  }

  #-----------------------------------------------------------------------------
  submethod BUILD ( ) {

    for $lorem-texts.keys -> $k {
      $lorem-texts{$k}<length> = $lorem-texts{$k}<text>.chars;
    }
  }

  #-----------------------------------------------------------------------------
  method standard1500 ( SemiXML::Element $m ) {

    my Str $ipsum = Q:to/EOIPSUM/;
        Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
        eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim
        ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut
        aliquip ex ea commodo consequat. Duis aute irure dolor in
        reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
        pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
        culpa qui officia deserunt mollit anim id est laborum.
        EOIPSUM

    $m.before(SemiXML::Text.new(:text($ipsum)));
  }

  #-----------------------------------------------------------------------------
  method cicero45bc ( SemiXML::Element $m ) {

    my Str $ipsum = Q:to/EOIPSUM/;
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

    $m.before(SemiXML::Text.new(:text($ipsum)));
  }

  #-----------------------------------------------------------------------------
  method cupcake-ipsum ( SemiXML::Element $m ) {

    my Str $ipsum = Q:to/EOIPSUM/;
        Cupcake ipsum dolor sit. Amet I love liquorice jujubes pudding
        croissant I love pudding. Apple pie macaroon toffee jujubes pie tart
        cookie applicake caramels. Halvah macaroon I love lollipop. Wypas I
        love pudding brownie cheesecake tart jelly-o. Bear claw cookie
        chocolate bar jujubes toffee.
        EOIPSUM

    $m.before(SemiXML::Text.new(:text($ipsum)));
  }

  #-----------------------------------------------------------------------------
  method samuel-ipsum ( SemiXML::Element $m ) {

    my Str $ipsum = Q:to/EOIPSUM/;
        Now that there is the Tec-9, a crappy spray gun from South Miami.
        This gun is advertised as the most popular gun in American crime. Do
        you believe that shit? It actually says that in the little book that
        comes with it: the most popular gun in American crime. Like they're
        actually proud of that shit.
        EOIPSUM

    $m.before(SemiXML::Text.new(:text($ipsum)));
  }

  #-----------------------------------------------------------------------------
  method bacon-ipsum ( SemiXML::Element $m ) {

    my Str $ipsum = Q:to/EOIPSUM/;
        Bacon ipsum dolor sit amet salami jowl corned beef, andouille flank
        tongue ball tip kielbasa pastrami tri-tip meatloaf short loin beef
        biltong. Cow bresaola ground round strip steak fatback meatball
        shoulder leberkas pastrami sausage corned beef t-bone pork belly
        drumstick.
        EOIPSUM

    $m.before(SemiXML::Text.new(:text($ipsum)));
  }

  #-----------------------------------------------------------------------------
  method tuna-ipsum ( SemiXML::Element $m ) {

    my Str $ipsum = Q:to/EOIPSUM/;
        Moonfish, steelhead, lamprey southern flounder tadpole fish sculpin
        bigeye, blue-redstripe danio collared dogfish. Smalleye squaretail
        goldfish arowana butterflyfish pipefish wolf-herring jewel tetra,
        shiner; gibberfish red velvetfish. Thornyhead yellowfin pike
        threadsail ayu cutlassfish.
        EOIPSUM

    $m.before(SemiXML::Text.new(:text($ipsum)));
  }

  #-----------------------------------------------------------------------------
  method veggie-ipsum ( SemiXML::Element $m ) {

    my Str $ipsum = Q:qq:to/EOIPSUM/;
        Veggies sunt bona vobis, proinde vos postulo esse magis grape pea
        sprouts horseradish courgette maize spinach prairie turnip jicama
        coriander quandong gourd broccoli seakale gumbo. Parsley corn
        lentil zucchini radicchio maize horseradish courgette maize spinach
        prairie turnip \x[00ED]cama coriander quandong burdock avocado
        sea lettuce. Garbanzo tigernut earthnut pea fennel.
        EOIPSUM

    $m.before(SemiXML::Text.new(:text($ipsum)));
  }

  #-----------------------------------------------------------------------------
  method cheese-ipsum ( SemiXML::Element $m ) {

    my Str $ipsum = Q:to/EOIPSUM/;
        I love cheese, especially airedale queso. Cheese and biscuits
        halloumi cauliflower cheese cottage cheese swiss boursin fondue
        caerphilly. Cow port-salut camembert de normandie macaroni cheese
        feta who moved my cheese babybel boursin. Red leicester roquefort
        boursin squirty cheese jarlsberg blue castello caerphilly chalk
        and cheese. Lancashire.
        EOIPSUM

    $m.before(SemiXML::Text.new(:text($ipsum)));
  }

  #-----------------------------------------------------------------------------
  # Generate words by calling make-words
  method words ( SemiXML::Element $m ) {

    # get the number of words
    my Int $nbr-words = ($attrs<n> // 1).Str.Int;

    my Str $ipsum;
    $ipsum ~= self!make-word ~ ' ' for ^$nbr-words;

    $ipsum ~~ s:g/ <punct>+ //;
    $ipsum ~~ s:g/ ^\s+ //;
    $ipsum ~~ s:g/ \s+ $//;
    $ipsum ~~ s:g/ \s+\s / /;

    $ipsum .= lc;
    $ipsum .= tc if ? $attrs{'tc'};
    $ipsum .= uc if ? $attrs{'uc'};

    $m.before(SemiXML::Text.new(:text($ipsum)));
  }

  #-----------------------------------------------------------------------------
  # Generate a sentence using words from the text
  method sentence ( SemiXML::Element $m ) {

    my Str $ipsum = self!make-sentence;
    $m.before(SemiXML::Text.new(:text($ipsum)));
  }

  #-----------------------------------------------------------------------------
  # Generate sentences by calling sentence a few times
  method sentences ( SemiXML::Element $m ) {

    # get the number of sentences
    my Int $nbr-sentences = ($attrs<n> // 1).Str.Int;

    # use that point to get some words from the text
    my Str $ipsum = '';
    for ^$nbr-sentences {
      $ipsum ~= self!make-sentence;
    }

    $m.before(SemiXML::Text.new(:text($ipsum)));
  }

  #-----------------------------------------------------------------------------
  # Generate sentences by calling sentence a few times
  method paragraph ( SemiXML::Element $m ) {

    # get the number of sentences
    my Int $nbr-paragraphs = (~$attrs<n> // 1).Int;

    # use that point to get some words from the text
    for ^$nbr-paragraphs {
      my Str $ipsum = '';
      $ipsum ~= self!make-sentence ~ '. ' for ^(4 + (4.rand.Int));
      $m.before.( 'p', :text($ipsum));
    }
  }

  #-----------------------------------------------------------------------------
  #-----------------------------------------------------------------------------
  method !make-sentence ( --> Str ) {

    # get some point in the first half of the text and find the next space
    my Int $start = $lorem-texts<perl5-lorem><text>.index(
      ' ', (($lorem-texts<perl5-lorem><length>)/2).rand.Int
    );

    # use that point to get some words from the text
    my Str $ipsum = $lorem-texts<perl5-lorem><text>.substr($start).comb(
      /\w+/, 4 + 6.rand.Int
    ).join(' ').tc;

    "$ipsum. ";
  }

  #-----------------------------------------------------------------------------
  method !make-word ( --> Str ) {

    # get some point in the first half of the text and find the next space
    my Int $start1 = 0;
    my Int $start2 = 0;
    repeat until ( ? $start1 and ?$start2 and ($start2 - $start1 > 1) ) {
      $start1 = $lorem-texts<perl5-lorem><text>.index(
        ' ', (($lorem-texts<perl5-lorem><length>) - 20).rand.Int
      );
      $start2 = $lorem-texts<perl5-lorem><text>.index( ' ', $start1 + 1);
    }

    # use the points to get a words from the text
    $lorem-texts<perl5-lorem><text>.substr( $start1, $start2 - $start1);
  }
}
