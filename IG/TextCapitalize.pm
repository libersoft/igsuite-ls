## IGSuite 4.0.0
## Procedure: TextCapitalize.pm
## Last update: 25/05/2009
#############################################################################
# IGSuite 4.0.0 - Provides an Office Suite by  simple web interface         #
# Copyright (C) 2002 Dante Ortolani  [LucaS]                                #
#                                                                           #
# AUTHOR                                                                    #
#                                                                           #
#   Joseph M. Brenner                                                       #
#      E-Mail:   doom@kzsu.stanford.edu                                     #
#      Homepage: http://www.grin.net/~mirthless/                            #
#                                                                           #
#   Stanislaw Y. Pusep                                                      #
#      E-Mail:	stanis@linuxmail.org                                        #
#      ICQ UIN:	11979567                                                    #
#      Homepage:	http://sysdlabs.hypermart.net/                      #
#                                                                           #
#   (And many thanks to Belden Lyman, for feature                           #
#   suggestions and code examples.)                                         #
#                                                                           #
#############################################################################

package Text::Capitalize;

use 5.004;
use strict;

use locale;
use Carp;
use Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

use vars qw($DEBUG);
$DEBUG = 0;

@ISA		= qw(Exporter);
@EXPORT		= qw(capitalize capitalize_title);
@EXPORT_OK      = qw(@exceptions 
                     %defaults_capitalize_title 
                     scramble_case
                     random_case
                     zippify_case
                    ); 
$VERSION	= '0.5';

# Define the pattern to match "exceptions": the minor words 
# that don't usually get capitalized in titles (used by capitalize_title)
use vars qw(@exceptions);
@exceptions = qw(
     a an the 
     and or nor for but so yet 
     to of by at for but in with has
     de von
     il lo la i gli le un uno una
  );

# Define the default arguments for the capitalize_title function
use vars qw(%defaults_capitalize_title);
%defaults_capitalize_title = (
             PRESERVE_WHITESPACE => 0,
             PRESERVE_ALLCAPS    => 0,
             PRESERVE_ANYCAPS    => 0,
             NOT_CAPITALIZED     => \@exceptions,
            );


# Defining patterns to match "words" and "sentences" (used by capitalize_title)

use vars qw($word_rule $sentence_rule);
use vars qw($anything $ellipsis $dot $qmark $emdash $terminator $ws);

$word_rule =  qr{ ([^\w\s]*)   # $1 - leading punctuation 
                               #   (e.g. ellipsis, leading apostrophe)
                   ([\w']*)    # $2 - the word itself (includes non-leading apostrophes)
                   ([^\w\s]*)  # $3 - trailing punctuation 
                               #   (e.g. comma, ellipsis, period)
                   (\s*)       # $4 - trailing whitespace 
                               #   (usually " ", though at EOL prob "")
                 }x ;

# Pieces for the $sentence_rule
$anything =    qr{.*?};  
$ellipsis =    qr{\Q...};
$dot =         qr{\Q.};
$qmark =       qr{\Q?};
$emdash =      qr{\Q--};
$terminator =  qr{$ellipsis|$dot|$qmark|!|:|$emdash|$};
$ws =          qr{\s*};

$sentence_rule = 
  qr{  (    $anything       # anything up to... 
            $terminator     # any sentence terminator (*or* the EOS)
            $ws             # trailing whitespace, if any
       )                    # all captured to $1
    }ox;


sub capitalize {
   local $_ = shift;
   s/\b(.*?)\b/$1 eq uc $1 ? $1 : "\u\L$1"/ge; 
   return $_;
}

sub capitalize_title { 
  local $_;
  my ($keep_ws, $keep_acronyms, $keep_mixups);
  my ($leading_whitespace, $string, $sentence, @words, $word, $spc);
  my ($punct_leading, $punct_trailing);
  my ($i, $first, $last);
  my ($new_string, $new_sentence,  $exception_rule, $exceptions_or);

  $string = shift;

  ($DEBUG) && print STDERR "\nUsing Text::Capitalize from the Wall: $0 \n";

  my %args = (%defaults_capitalize_title,
              @_   # imports the argument pair list, if any
              );

  # Checking for spelling errors in options 
  # (locked hashes are still too new for me).
  foreach (keys %args) { 
    unless (exists $defaults_capitalize_title{$_}) { 
      carp "Bad option $_\n";
    }
  }

  $keep_ws =       $args{PRESERVE_WHITESPACE};
  $keep_acronyms = $args{PRESERVE_ALLCAPS};
  $keep_mixups =   $args{PRESERVE_ANYCAPS};

  $exceptions_or = join '|', @{ $args{NOT_CAPITALIZED} };
  $exception_rule = qr/^(?:$exceptions_or)$/oi;  

  $new_string = "";

  # Process each sentence in the string
  # (titles *can* have multiple sentences -- especially
  # since I'm calling ":" a sentence delimeter...)

  while ( $string =~ /$sentence_rule/g ) {
    $sentence = $1;
    $new_sentence = "";  @words = ();

    my $i = 0;
    while ($sentence =~ /$word_rule/g) {
      # Find each word in the sentence. Stash this 
      # along with ancilliary characters, like trailing whitespace and 
      # leading or trailing punctuation  (e.g. "...and", "'em", "and...", "F.B.I.")
      # in an anonymous array in the array @words

      # If we've matched something, load it
      # (checking because the above pattern returns an empty "match" at the end)
       if ( ($2 ne '') or $1 or $3 or ($4 ne '') ) {   
          $words[$i] = [$1, $2, $3, $4]; # That is: $punct_leading, $word, $punct_trailing, $spc
          $i++; 
        }
     }

    # Now process each word

    # (Using a for loop here with an explicit counter,
    # because it makes it easier to know when you're doing
    # the first and last words)

    $first = 0;
    $last = $#words; 
    for ($i=$first; $i<=$last; $i++) { 
       {  # need nested block because you can't have a "continue" with a mere for loop
         ($punct_leading, $word, $punct_trailing, $spc) = ( @{ $words[$i] } );

         # collapse whitespace to one space, unless we need to preserve it
         unless ($keep_ws) { 
           $spc = " " if (length($spc) > 0); 
         } 

         $_ = $word;   # following operations act on the current word

         # Check for a word with *any* capitals (e.g. "iMac, NeXt, Boom, BOOM"), 
         # when they're being passed through untouched.
         if ( ($keep_mixups) && ( /[[:upper:]]/ ) ) {  
            next;
         }

         # Check for an all uppercase word, but only
         # when they're being passed through.
         if ( ($keep_acronyms) && ( /^[[:upper:]]+$/) ) {  
           next;
         }

         # Tweaks to get some French names to work, e.g. "d'Alembert", "l'Hospital"
         # (into the best laid algorithms, some fugliness must creep)
         if ( /^[dl]'/) {
            s{ ^(d') (\w) }{ lc($1) . uc($2) }iex;
            s{ ^(l') (\w) }{ lc($1) . uc($2) }iex;

            # But upcase first char if first or last word
            if ( ($i == $first) or ($i == $last) ) { 
                $_ = ucfirst;
            }
            next;
         }

         # The first word and the last are capitalized even if
         # they're on the exception list:

         if ( ($i == $first) or ($i == $last) ) {
             $_ = ucfirst( lc );
             next;
         }

         # Typically, words on the exception list are lowercase, all others are upper-cased
         if ( /$exception_rule/ ) {
            $_ = lc;
         } else {
            $_ = ucfirst( lc );
         }

       } continue { # Append word to the new sentence
         $new_sentence .=  $punct_leading . $_ . $punct_trailing . $spc;
       }
    }  # end of per word for loop
    
    $new_string .= $new_sentence;  

  } # end of per sentence loop.

  # If we're not preserving whitespace, 
  # get rid of the leading or trailing spaces.
  # (Doing this here, as a final step, to avoid dropping spaces *between* sentences.)
  unless ($keep_ws) { 
    $new_string =~ s|^\s+||; 
    $new_string =~ s|\s+$||; 
  }

  return $new_string;
} # end sub capitalize_title
 
sub scramble_case { 
   # Function to provide a special effect: sCraMBliNg tHe CaSe
   local $_;
   my $string = shift;
   my (@chars, $uppity, $newstring, $total, $uppers, $downers, $tweak);
   @chars = split /(?=.)/, $string;

   # Instead of initializing to zero, using fudged initial counts to 
   #   (1) provide an initial bias against leading with uppercase, 
   #   (2) eliminate need to watch for division by zero on $tweak below.

   $uppers = 2; 
   $downers = 1;
   foreach (@chars) { 

      # Rather than "int(rand(2))" which generates a 50/50 distribution of 0s and 1s,
      # we're using "int(rand(1+$tweak))" where $tweak will
      # provide a restoring force back to the average
      # So here we want $tweak:
      #    to go to 1 when you approach $uppers = $downers
      #    to be larger than 1 if $downers > $uppers
      #    to be less than 1 if $uppers > $downers
      # Simple formula that does this:

      $tweak = $downers/$uppers;
      $uppity = int( rand(1 + $tweak) ); 

      if ($uppity) {
         $_ = uc;
         $uppers++;
       } else { 
         $_ = lc;
         $downers++;
       }
   }
   $newstring = join '', @chars;
   return $newstring;
}

sub random_case { 
#  Provided for comparison to scramble_case
   local $_;
   my $string = shift;
   my (@chars, $uppity, $newstring);
   @chars = split /(?=.)/, $string;

   foreach (@chars) { 
      $uppity = int ( rand(2) ); # simple, 50-50 random pick

      if ($uppity) {
         $_ = uc;
       } else { 
         $_ = lc;
       }
   }
   $newstring = join '', @chars;
   return $newstring;
}


sub zippify_case { 

   # Function to provide a special effect: RANDOMLY upcasing WHOLE WORDS at a TIME

   # This uses a similar algorithm to scramble_case, though it also
   # ignores words on the @exceptions list, just as capitalize_title does.

   local $_;
   my $string = shift;
   my (@words, $uppity, $newstring, $total, $uppers, $downers, $tweak, $word);
   @words = split /\b/, $string;

   # Instead of initializing to zero, using fudged initial counts to 
   #   (1) provide an initial bias *toward* leading with uppercase, 
   #   (2) eliminate need to watch for division by zero on $tweak below.

   $uppers = 1; 
   $downers = 5;
   WORD: foreach $word (@words) { 
      foreach (@exceptions) {
        next WORD if m/\Q$word\E/i;
      }

      # Just as with scramble_case, we're using a simple "$tweak" formula 
      # here to to get a modified "random" distribution with fewer 
      # "streaks" than normal.

      $tweak = $downers/$uppers;
      $uppity = int( rand(1 + $tweak) ); 

      if ($uppity) {
         $word = uc($word);
         $uppers++;
       } else { 
         $word = lc($word);
         $downers++;
       }
   }
   $newstring = join '', @words;
   return $newstring;
}



1;

__END__

=head1 NAME

Text::Capitalize - capitalize strings ("to WORK AS titles" becomes "To Work as Titles")

=head1 SYNOPSIS

   use Text::Capitalize;

   print capitalize("...and justice for all"), "\n";
      ...And Justice For All

   print capitalize_title("...and justice for all"), "\n";
      ...And Justice for All

   print capitalize_title("agent of SFPUG", PRESERVE_ALLCAPS=>1 ), "\n";
      Agent of SFPUG

   print capitalize_title("the ring:  symbol or cliche?", PRESERVE_WHITESPACE=>1 ), "\n";
      The Ring:  Symbol or Cliche?
      (Note, double-space after colon is still there.)

   # To work on international characters, may need to set locale to something appropriate
   use Env qw(LANG);
   $LANG = "en_US";
   print capitalize_title("über maus"), "\n";
      Über Maus

   use Text::Capitalize qw(scramble_case);
   print scramble_case('It depends on what you mean by "mean"');
      It dEpenDS On wHAT YOu mEan by "meAn".





=head1 ABSTRACT

  Text::Capitalize is for capitalizing strings in a manner 
suitable for use in titles. 

=head1 DESCRIPTION

Text::Capitalize provides a few different flavors of procedures
for B<title-like> formatting for strings.

For the "capitalize" function B<Title-like> (written by
Stanislaw Y. Pusep) formatting consists of ensuring that the
first letter of each word is uppercase, and that the rest is
lowercase.

The "capitalize_title" function tries to get closer to 
English title capitalization rules (discussed below) where 
only the "important" words are supposed to be capitalized.
There are also some customization features provided to allow 
the user to choose variant rules.

Examples of title formatting with "capitalize":

=over

=item 'lost watches of splitsville' becomes 'Lost Watches Of Splitsville'

=item 'KiLLiNG TiMe' becomes 'Killing Time'

=back

Some simple examples of title formatting with "capitalize_title":

=over 

=item 'we have come to wound the autumnal city' becomes 'We Have Come to Wound the Autumnal City'

=item 'ask for whom they ask for' becomes 'Ask for Whom They Ask For'

=back

Text::Capitalize also provides some functions for special effects 
such as "scramble_case", which typically would be used for this sort 
of transformation:

=over

=item 'get whacky' might become 'gET wHaCkY'

=back

=head1 BACKGROUND

The capitalize_title function makes an attempt at doing the
right thing by default.  The goal is to take an arbitrary
chunk of text and adjust it automatically so that it can
be used as a title... But as with many aspects of the human
languages, it is extremely difficult to come up with a set
of programmatic rules that will cover all cases.  

=head2 Words that don't get capitalized

This web page:

  http://www.continentallocating.com/World.Literature/General2/LiteraryTitles2.htm

presents some admirably clear rules for capitalizing titles:

  ALL words in EVERY title are capitalized except
  (1) a, an, and the,
  (2) two and three letter conjunctions (and, or, nor, for, but, so, yet), 
  (3) prepositions.  
  Exceptions:  The first and last words are always capitalized even 
  if they are among the above three groups.

But consider the case:

  "It Waits Underneath the Sea"

Should the word "underneath" be downcased because it's a preposition? 
Most English speakers would be surprised to see it that way.
Consequently, the default list of exceptions to capitalization in this module 
only includes the shortest of the common prepositions (to of by at for but in).  

The default entries on the exception list are:

     a an the 
     and or nor for but so yet 
     to of by at for but in with has
     de von

The observant may note that the last row is not
composed of English words.  The honorary "de" has been 
included in honor of "Honoré de Balzac". 
And "von" was added for the sake of equal time.

=head2 Customizing the Exceptions to Capitalization

If you have different ideas about the "rules" of English
(or perhaps if you're trying to use this code with another 
language with different rules) you might like to substitute 
a new exception list of your own:

    print capitalize_title("Dude, we, like, went to Old Slavy, and uh, they didn't have it",
                           NOT_CAPITALIZED => [qw(uh duh huh wha like man you know)]);

    This should output:
        Dude, We, like, Went To Old Slavy, And uh, They Didn't Have It


Less radically, you might like to simply add a word to the list,
for example "from":

    use Text::Capitalize 0.2 qw(capitalize_title @exceptions);
    push @exceptions, "from";

    print capitalize_title("fungi from yuggoth", 
                           NOT_CAPITALIZED => \@exceptions);

    This should output:
        Fungi from Yuggoth

=head2 All Uppercase Words

In order to work with a wide range of input strings, by default
capitalize_title presumes that upper-case input needs to be adjusted
(e.g. "DOOM APPROACHES!" would become "Doom Approaches!").  But, this
doesn't allow for the possibilities such as an acronym in a title
(e.g. "RAM Prices Plummet" ideally should not become "Ram Prices
Plummet").  If the PRESERVE_ALLCAPS option is set, then it will be
presumed that an all-uppercase word is that way for a reason, and
will be left alone:

   print capitalize_title("ram more RAM down your throat", 
                       PRESERVE_ALLCAPS => 1);

   This should output:
      Ram More RAM Down Your Throat

=head2 Preserving Any Usage of Uppercase for Mixed-case Words

There are some other odd cases that are difficult to handle well,
notably mixed-case words such as "iMac", "CHiPs", and so on.  For
these purposes, a PRESERVE_ANYCAPS option has been provided which
presumes that any usage of uppercase is there for a reason, in which
case the entire word should be passed through untouched.  With
PRESERVE_ANYCAPS on, only the case of all lowercase words will ever
be adjusted:

    print capitalize_title("TLAs i have known and loved", 
                       PRESERVE_ANYCAPS => 1);

   This should output:
       TLAs I Have Known and Loved

    print capitalize_title("the next iMac: just another NeXt?", 
                           PRESERVE_ANYCAPS => 1);

   This should output:
       The Next iMac: Just Another NeXt?


=head2 Handling Whitespace

By default, the capitalize_title function presumes that you're trying
to clean up potential title strings. As an extra feature it collapses
multiple spaces and tabs into single spaces.  If this feature doesn't
seem desirable and you want it to literally restrict itself to
adjusting capitalization, you can force that behavior with the
PRESERVE_WHITESPACE option:

    print capitalize_title("it came from texas:  the new new world order?", 
                           PRESERVE_WHITESPACE => 1);

   This should output:
      It Came From Texas:  The New New World Order?
   (Note: the double-space after the colon is still there.)

=head2 Comparison to Text::Autoformat

As you might expect, there's more than one way to do this, 
and these two pieces of code perform very similar functions:

   use Text::Capitalize 0.2;
   print capitalize_title($t), "\n";

   use Text::Autoformat;
   print autoformat{case => "highlight", right=>length($t)}, $t;

Note: supplying the length of the string as the "right margin"
is a performance hack: this is much faster than plugging in an
arbitrarily large number.  There doesn't seem to be any other
way of turning off line-breaking (e.g. by using the "fill"
parameter) though possibly there will be in the future.

As of this writing, "capitalize_title" has some advantages:

=over 

=item 1. 

It works on characters outside the English 7-bit ASCII
range, for example with my locale setting (en_US) the
ISO-8859-1 International characters are handled correctly,
so that "über maus" becomes "Über Maus".

=item 2. 

Minor words following leading punctuation become upper case: 

   "...And Justice for All"

=item 3. 

It works with multiple sentence input (e.g. "And sooner. And later." 
should probably not be "And sooner. and later.")

=item 4. 

The list of minor words is more extensive (i.e. includes: so, yet, nor),
and is also customizable.

=item 5. 

There's a method of preserving acronyms via the PRESERVE_ALLCAPS flag
and similarly, mixed-case words ("iMac", "NeXt", etc") with the 
PRESERVE_ANYCAPS flag.

=item 6. 

capitalize_title is roughly ten times faster.

=back

Another difference is that Text::Autoformat's "highlight"
always preserves whitespace something like capitalize_title 
does with the PRESERVE_WHITESPACE option set.

However, it should be pointed out that Text::Autoformat is under
active maintenance by Damian Conway (and does far more than this 
module does): it's recommended that you look into using it. 

=head2 Still more ways to do it

Late breaking news: The second edition of the Perl Cookbook
has just come out.  It now includes: "Properly Capitalizing
a Title or Headline" as recipe 1.14.  You should
familiarize yourself with this if you want to become a true 
master of all title capitalization routines.

(And I see that recipe 1.13 includes a "randcap" program as
an example, which as it happens does something like the
random_case function described below...)

=head1 SPECIAL EFFECTS 

Some functions have been provided to make strings look weird
by scrambling their capitalization ("lIKe tHiS"):
random_case and scramble_case.  The function "random_case"
does a straight-forward randomization of capitalization so 
that each letter has a 50-50 chance of being upper or lower 
case.  The function "scramble_case" performs a very similar 
function, but does a slightly better job of producing something 
"weird-looking".

The difficulty is that there are differences between human
perception of randomness and actual randomness.  Consider
the fact that of the sixteen ways that the four letter word
"word" can be capitalized, three of them are rather boring:
"word", "Word" and "WORD".  To make it less likely that
scramble_case will produce dull output when you want "weird"
output, a modified probability distribution has been used
that records the history of previous outcomes, and tweaks
the likelihood of the next decision in the opposite
direction, back toward the expected average.  In effect,
this simulates a world in which the Gambler's Fallacy is
correct ("Hm... red has come up a lot, I bet that black is
going to come up now."). "Streaks" are much less likely 
with scramble_case than with random_case.

Additionally, with scramble_case the probability that the
first character of the input string will become upper-case
has been tweaked to less than 50%.  (Future versions may
apply this tweak on a per-word basis rather than just on a
per-string basis).

There is also a function that scrambles capitalization on 
a word-by-word basis called "zippify_case", which should produce output 
like: "In my PREVIOUS life i was a LATEX-novelty REPAIRMAN!"


=head1 EXPORT

By default, this version of the module provides the two
functions capitalize and capitalize_title.  Future versions 
will have no further additions to the default export list.

Optionally, the following functions may also be exported:  

=over

=item scramble_case - function to scramble capitalization in 
a wEiRD loOOkInG wAy.  Supposed to look a little stranger than the simpler 
random_case output

=item random_case - function to randomize capitalization of each letter 
in the string.  Compare to "scramble_case"

=item zippify_case - a function like "scramble_case" that acts on
a word-by-word basis (Somewhat LIKE this, YOU know?).

=back

It is also possible to export the following variables:

=over

=item @exceptions - The list of minor words that
capitalize_title uses by default to determine the exceptions to
capitalization.

=item %defaults-capitalize_title - The hash of allowed arguments
(with defaults) that the capitalize_title function uses.

=back

=head1 BUGS 

1. In capitalize_title, quoted sentence terminators are
treated as actual sentence breaks, e.g. in this case:

     'say "yes but!" and "know what?"'

The program sees the ! and effectively treats this as two
separate sentences: the word "but" becomes "But" (under the
rule that last words must always be uppercase, even if they're
on the exception list) and the word "and" becomes "And" (under
the first word rule).

2. Currently there's no good way to automatically handle
names like "McCoy".  Consider the difficulty of disambiguating
"Macadam Roads" from "MacAdam Rode".  If you need to solve
problems like this, look into using the case_surname function of
Lingua::En::NameParse.

3. In general, Text::Capitalize is a very parochial
English oriented module, that looks like it belongs in the
"Lingua::En::*" tree.  Someday it may become more general.

4. There's currently no way of doing a PRESERVE_ANYCAPS
that *also* adjusts capitalization of words on the exception
list, so that "iMac Or iPod" would become "iMac or iPod".


=head1 SEE ALSO

  Text::Autoformat

  "The Perl Cookbook", second edition, recipes 1.13 and 1.14

  Lingua::En::NameParse

=head1 VERSION

Version 0.5

=head1 AUTHORS

   Joseph M. Brenner 
      E-Mail:   doom@kzsu.stanford.edu
      Homepage: http://www.grin.net/~mirthless/

   Stanislaw Y. Pusep
      E-Mail:	stanis@linuxmail.org
      ICQ UIN:	11979567
      Homepage:	http://sysdlabs.hypermart.net/

   (And many thanks to Belden Lyman, for feature 
   suggestions and code examples.)

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Joseph Brenner. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut


