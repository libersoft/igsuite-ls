## IGSuite 4.0.0
## Plugin: example.pm
## Last update: 25/05/2009
#############################################################################
# IGSuite 4.0.0 - Provides an Office Suite by  simple web interface         #
# Copyright (C) 2002 Dante Ortolani  [LucaS]                                #
#############################################################################


## Insert a brief description of your plugin. Remember to quote \'
my $PluginDescription = 'This is an example';


## Insert here minimum IGSuite version required
##
my $NeedIgSuiteVersion = '4.0.0';


## Specify all available hooks to IGSuite framework functions.
## Remember you can hook only these core functions:
## HtmlHead() HtmlFoot() DocHead()  HttpHead() TaskHead()  MkComments()
## TaskFoot() Button()   FormHead() FormFoot() ParseLink() TabPane()
##
## my %HooksFunctions = ( HtmlFoot  => 'htmlfoot',
##                        DocHead   => 'mydochead',
##                        Button    => 'my_fake_button' );
##
my %HooksFunctions = ( HtmlFoot  => 'htmlfoot' );


## You can limit plugin action to a specific cgi script. Edit
## %LimitToScripts and insert all script that can use this plugin 
my %LimitToScripts = (
#                     letters => 1,
#                     offers  => 1,
                     );


## You can limit plugin to a specific action reported in $on{action}. Edit
## %LimitToActions and insert all action that can use this plugin 
my %LimitToActions = (
#                     proto   => 1,
#                     delexec => 1,
                     );


## If your plugin need global variables, they must be declared here.
##
use vars qw/
$PluginVariableSample
/;


## Here are all possible hooks to IGSuite framework functions. For each new
## hook you have to insert an item to %HooksFunctions above.
## NOTE THAT IN PLUGINS' FUNCTIONS, YOU CAN USE ANY IGSUITE GLOBAL VARIALES.
##
sub htmlfoot
 {
  ## This example add a simple comment to the end of the html page
  my ($html, %data) = @_;
  my $comment = "\n<!--\nThis page is parsed by an external plugin\n-->\n";
  return $comment . $html;
 }


###########################################################################
###########################################################################
## Don't edit this init function. igsuited need it to register the plugin
##
sub init
 {
  my $PluginName = shift;
  return IG::PluginRegister( name             => $PluginName,
                             version          => $NeedIgSuiteVersion,
                             description      => $PluginDescription,
                             limit_to_scripts => \%LimitToScripts,
                             limit_to_actions => \%LimitToActions,
                             functions        => \%HooksFunctions );
 }

1; ## DON'T REMOVE THIS LINE AND KEEP IT AS LAST PLUGIN LINE
