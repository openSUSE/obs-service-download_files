#!/usr/bin/env perl
use FindBin;
use Cwd;

use Path::Class qw/dir/;
use Test::More tests => 3;

{
package MyWebServer;

use HTTP::Server::Simple::CGI;
use Path::Class qw/file/;
use base qw(HTTP::Server::Simple::CGI);



my %dispatch = (
  '/data/Test-Simple-1.001014.tar.gz' => \&dl_handler
);

sub handle_request {
   my $self = shift;
   my $cgi  = shift;
 
   my $path = $cgi->path_info();
   my $handler = $dispatch{$path};

   if (ref($handler) eq "CODE") {
       print "HTTP/1.0 200 OK\r\n";
       $handler->($path);
       
   } else {
       print "HTTP/1.0 404 Not found\r\n";
       print $cgi->header,
             $cgi->start_html('Not found'),
             $cgi->h1('Not found'),
             $cgi->end_html;
   }
}
 
sub dl_handler {
  my $path = shift;

  my $f = file('.',$path);

  my $fc = $f->slurp();
  my $l = length($fc);
  print "Content-Type: application/x-gzip\r\n";
  print "Content-Length: $l\r\n\r\n";
  print $fc;

}

} 

my $dir     = getcwd();
my $outdir  = dir($FindBin::Bin,"tmp");

dir($outdir)->rmtree;
mkdir $outdir;
chdir $FindBin::Bin || die;

my $pid;

{ 
  local *STDOUT;
  my $out="";
  open(STDOUT,'>',\$out);
  $pid = MyWebServer->new(8080)->background();
}

# Checking command
my $cmd="../download_files --outdir ".$outdir->stringify." --recompress yes";
`$cmd`;
ok($? == 0,"Checking download with recompression");

# Checking file content
my $tar = "tar tvjf ".$outdir->stringify."/Test-Simple-1.001014.tar.bz2";
`$tar`;
ok($? == 0,"Checking extraction");

# checking cleanup
my @fl = $outdir->children();
ok(@fl == 1,"Checking cleanup");

# cleanup
$outdir->rmtree;
kill 15, $pid;

chdir $dir;

exit 0;
