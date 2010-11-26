#!/usr/bin/perl
#-----------------------------------------------------------------------------
#
#  comics-config.pl
#
#  This is a configuration file for comics.pl
#
#  http://www.remote.org/jochen/software/comics/
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

sub get_config {
  my %conf;

  #  *** EDIT AT LEAST THE FOLLOWING THREE DEFINITIONS ***

  # This is the mail address where the comics will be mailed to
  $conf{'DEFAULT_MAIL_ADDR'} = 'foo@example.com';

  # This is the directory where the comics.pl script remembers which comics
  # it has already seen. The user running the comics.pl script needs write
  # access here.
  $conf{'HISTORY_DIR'} = "/tmp/history";

  # This is the directory where the comics.pl script archives all comics.
  # The user running the comics.pl script needs write access here.
  $conf{'ARCHIVE_DIR'} = "/tmp/archive";

  # Set this to 0 if you don't want debug messages.
  $conf{'DEBUG'} = 1;


#-----------------------------------------------------------------------------
#
#  The following configuration tells comics.pl where to find the comics and
#  some other details.
#
#  id       - Unique ID of this comic. Is used for file names etc. so no
#             spaces or "strange" chars allowed.
#  name     - Real name of this comic.
#  mail     - List of mail addresses this comic should be sent to. If
#             there is no 'mail' entry, the default address in the variable
#             $DEFAULT_MAIL_ADDR is used.
#  mimetype - MIME type of picture.
#  urls     - List of URLs and patterns. The program loads each URL from the
#             the list in turn and matches the pattern to the web page. The
#             next URL can be determined (partially) by the preceding pattern.
#             In that case, $M in the URL will be replaced by the string from
#             the page that matched the part enclosed in ().
#
#-----------------------------------------------------------------------------


  my @conf = ( {
#-----------------------------------------------------------------------------
  id    => 'dilbert',
  name  => 'Dilbert',
  mimetype  => 'image/gif',
  urls  => [ {
    url => 'http://www.dilbert.com/',
    pat => 'IMG SRC=\"(/comics/dilbert/archive/images/dilbert.*\.gif)\" BORDER=0 ALT=\"Today\'s Dilbert Comic\"',
  }, {
    url => 'http://www.dilbert.com$M',
    pat => undef,
  } ],
}, {
#-----------------------------------------------------------------------------
  id    => 'userfriendly',
  name  => 'Userfriendly',
  mimetype  => 'image/gif',
  urls  => [ {
    url => 'http://www.userfriendly.org/static/',
    pat => 'IMG ALT=\"Latest Strip\" .* SRC=\"(http://www.userfriendly.org/cartoons/archives/.*\.gif)',
  }, {
    url => '$M',
    pat => undef,
  } ],
});

  $conf{'COMICS'} = \@conf;

	return \%conf;
}


1;


#-- THE END ------------------------------------------------------------------
