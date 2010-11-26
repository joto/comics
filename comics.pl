#!/usr/bin/perl
#-----------------------------------------------------------------------------
#
#  comics.pl
#
#  Version 2.0
#
#  http://www.remote.org/jochen/software/comics/
#
#-----------------------------------------------------------------------------
#
#  To use this program, put the configuration in a file and call comics.pl
#  with the name of the configuration file as its sole command line argument.
#  An example for the configuration file can be found on the web page.
#
#-----------------------------------------------------------------------------
#
#  Copyright 2001 by Jochen Topf <jochen@remote.org>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA
#
#-----------------------------------------------------------------------------

use strict;
use MIME::Entity;
use LWP::UserAgent;

if (! defined $ARGV[0]) {
	die("No configuration! Call comics.pl with the name of the configuration\non the command line.\n");
}

require $ARGV[0];

my $conf = get_config();
my $DEBUG = $conf->{'DEBUG'};
my @conf = @{$conf->{'COMICS'}};


my %mime2suffix = (
  'image/jpeg' => 'jpg',
	'image/gif'  => 'gif',
);


my $ua = new LWP::UserAgent;
$ua->timeout(10);


foreach my $comic (@conf) {
  get_comic($ua, $comic);
}

exit 0;


#-----------------------------------------------------------------------------
sub get_comic {
  my ($ua, $comic) = @_;

  if ($DEBUG) {
    print STDERR "Getting comic id $comic->{'id'} (\"$comic->{'name'}\")\n";
  }

  my $url;
  my $M = "";
  my $response;
  foreach my $page (@{$comic->{'urls'}}) {
    eval "\$url = \"$page->{'url'}\"";
    if ($DEBUG) {
      print STDERR "  from URL |$url|\n";
    }

    my $request = new HTTP::Request('GET', $url);
    $response = $ua->request($request);
    unless ($response->is_success) {
      print STDERR "  error getting |$url| for id $comic->{'id'}\n";
      return;
    }

    last unless ($page->{'pat'});

    my $content = $response->content;

    if ($content !~ m|$page->{'pat'}|) {
      print STDERR "  no match using pattern |$page->{'pat'}| for id $comic->{'id'}\n";
      return;
    }
    $M = $1;
    print STDERR "  matched |$page->{'pat'}|\n" if ($DEBUG);
  }

  return if (in_history($comic, $url));

  my $content = $response->content;

  if (! send_comic($comic, $content)) {
    print STDERR "Can't send mail\n";
    return;
  }
  archive_comic($comic, $content);

  save_history($comic);
}


#-----------------------------------------------------------------------------
#
#  get_time()
#
#-----------------------------------------------------------------------------
sub get_time {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

  return sprintf("%04d-%02d-%02d", $year+1900, $mon+1, $mday);
}


#-----------------------------------------------------------------------------
#
#  archive_comic()
#
#-----------------------------------------------------------------------------
sub archive_comic {
  my ($comic, $content) = @_;

  my $dir = "$conf->{'ARCHIVE_DIR'}/$comic->{'id'}";

  mkdir($dir, 0755) if (! -d $dir);
  my $ts = get_time();
  if (! open(ARC, ">$dir/$ts-$comic->{'id'}.$mime2suffix{$comic->{'mimetype'}}")) {
    print STDERR "  error writing archive for id $comic->{'id'}: $!\n";
    return;
  }
  print ARC $content;
  close ARC;
}


#-----------------------------------------------------------------------------
#
#  send_comic()
#
#  Send mail with comic.
#
#-----------------------------------------------------------------------------
sub send_comic {
  my ($comic, $content) = @_;

  my $ts = get_time();

  my $addr = $comic->{'mail'} ? $comic->{'mail'} : $conf->{'DEFAULT_MAIL_ADDR'};

  my $top = build MIME::Entity From     => 'robot@remote.org',
                               To       => $addr,
                               Subject  => "$comic->{'name'} ($ts)",
                               Data     => $content,
                               Encoding => "base64",
                               Type     => $comic->{'mimetype'};

  $top->make_singlepart;

  open(SENDMAIL, "|/usr/sbin/sendmail -t") or return 0;
  $top->print(\*SENDMAIL);
  close SENDMAIL;

  return 1;
}


#-----------------------------------------------------------------------------
#
#  History handling
#
#-----------------------------------------------------------------------------
my @hist;		# this is used by in_history() and save_history()


#-----------------------------------------------------------------------------
#
#  in_history()
#
#-----------------------------------------------------------------------------
sub in_history {
  my ($comic, $url) = @_;

  @hist = ();
  if (! -f "$conf->{'HISTORY_DIR'}/$comic->{'id'}") {
    push(@hist, $url);
    return 0;
  }

  if (! open(HIST, "$conf->{'HISTORY_DIR'}/$comic->{'id'}")) {
    print STDERR "Can't open history at \"$conf->{'HISTORY_DIR'}/$comic->{'id'}\": $!\n";
    return 2;
  }

  while (<HIST>) {
    chomp;
    if ($_ eq $url) {
      close HIST;
      return 1;
    }
    push(@hist, $_);
  }
  close HIST;

  push(@hist, $url);
  return 0;
}


#-----------------------------------------------------------------------------
#
#  save_history()
#
#  Save history to file.
#
#-----------------------------------------------------------------------------
sub save_history {
  my ($comic) = @_;

  # shorten array
  shift @hist while ($#hist > 10);

  if (! open(HIST, ">$conf->{'HISTORY_DIR'}/$comic->{'id'}")) {
    print STDERR "Can't write to history at \"$conf->{'HISTORY_DIR'}/$comic->{'id'}\": $!\n";
    return;
  }

  foreach my $url (@hist) {
    print HIST "$url\n";
  }

  close HIST;

  return; 
}


#-- THE END ------------------------------------------------------------------
