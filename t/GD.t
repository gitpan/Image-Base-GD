#!/usr/bin/perl

# Copyright 2010 Kevin Ryde

# This file is part of Image-Base-GD.
#
# Image-Base-GD is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-GD is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-GD.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use Test::More tests => 58;

BEGIN {
#  SKIP: { eval 'use Test::NoWarnings; 1'
#            or skip 'Test::NoWarnings not available', 1; }
}

require Image::Base::GD;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 2;
  is ($Image::Base::GD::VERSION, $want_version, 'VERSION variable');
  is (Image::Base::GD->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Image::Base::GD->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Image::Base::GD->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $image = Image::Base::GD->new (-gd => 'dummy');
  is ($image->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $image->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $image->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# new()

{
  my $image = Image::Base::GD->new (-width => 6,
                                    -height => 7);
  is ($image->get('-file'), undef);
  is ($image->get('-zlib_compression'), -1);
  is ($image->get('-width'), 6);
  is ($image->get('-height'), 7);
  isa_ok ($image, 'Image::Base');
  isa_ok ($image, 'Image::Base::GD');
}

#------------------------------------------------------------------------------
# save() / load()

my $have_File_Temp = eval { require File::Temp; 1 };
if (! $have_File_Temp) {
  diag "File::Temp not available: $@";
}

SKIP: {
  $have_File_Temp
    or skip 'File::Temp not available', 6;

  my $fh = File::Temp->new;
  my $filename = $fh->filename;

  # save file
  {
    my $image = Image::Base::GD->new (-width => 1,
                                      -height => 1);
    $image->xy (0,0, '#FFFFFF');
    $image->set(-file => $filename,
                -zlib_compression => 1);
    is ($image->get('-file'), $filename);
    $image->save;
    cmp_ok (-s $filename, '>', 0);
  }

  # existing file with new(-file)
  {
    my $image = Image::Base::GD->new (-file => $filename);
    is ($image->get('-file'), $filename);
    is ($image->xy (0,0), '#FFFFFF');
  }

  # existing file with load()
  {
    my $image = Image::Base::GD->new (-width => 1,
                                      -height => 1);
    $image->load ($filename);
    is ($image->get('-file'), $filename);
    is ($image->xy (0,0), '#FFFFFF');
  }
}


#------------------------------------------------------------------------------
# colour_to_index

{
  my $image = Image::Base::GD->new (-width => 1, -height => 1);

  is ($image->colour_to_index('#000000'),
      $image->colour_to_index('#000000'));
  is ($image->colour_to_index('None'),
      $image->colour_to_index('None'));
}

#------------------------------------------------------------------------------
# line

{
  my $image = Image::Base::GD->new (-width => 20,
                                                    -height => 10);
  $image->rectangle (0,0, 19,9, '#000000', 1);
  $image->line (5,5, 8,8, '#FFFFFF', 0);
  is ($image->xy (4,4), '#000000');
  is ($image->xy (5,5), '#FFFFFF');
  is ($image->xy (5,6), '#000000');
  is ($image->xy (6,6), '#FFFFFF');
  is ($image->xy (7,7), '#FFFFFF');
  is ($image->xy (8,8), '#FFFFFF');
  is ($image->xy (9,9), '#000000');
}
{
  my $image = Image::Base::GD->new (-width => 20,
                                    -height => 10);
  $image->rectangle (0,0, 19,9, '#000000', 1);
  $image->line (0,0, 2,2, '#FFFFFF', 1);
  is ($image->xy (0,0), '#FFFFFF');
  is ($image->xy (1,1), '#FFFFFF');
  is ($image->xy (2,1), '#000000');
  is ($image->xy (3,3), '#000000');
}

#------------------------------------------------------------------------------
# xy

foreach my $truecolor (1,0) {
  GD::Image->trueColor($truecolor);
  my $image = Image::Base::GD->new (-width  => 100,
                                    -height => 100);
  $image->get('-gd')->alphaBlending(0);
  diag "isTrueColor: ",$image->get('-gd')->isTrueColor;

  $image->xy (50,60, '#112233');
  $image->xy (51,61, '#445566');
  $image->xy (52,62, 'black');
  $image->xy (53,63, 'white');
  $image->xy (54,64, 'None');
  is ($image->xy (50,60), '#112233', 'xy() 50,50');
  is ($image->xy (51,61), '#445566', 'xy() 51,51');
  is ($image->xy (52,62), '#000000', 'xy() 52,62');
  is ($image->xy (53,63), '#FFFFFF', 'xy() 53,63');
  is ($image->xy (54,64), 'None',    'xy() 54,64');
}

#------------------------------------------------------------------------------
# rectangle

{
  my $image = Image::Base::GD->new (-width => 20,
                                    -height => 10);
  $image->rectangle (0,0, 19,9, '#000000', 1);
  $image->rectangle (5,5, 7,7, '#FFFFFF', 0);
  is ($image->xy (5,5), '#FFFFFF');
  is ($image->xy (6,6), '#000000');
  is ($image->xy (7,6), '#FFFFFF');
  is ($image->xy (8,8), '#000000');
}
{
  my $image = Image::Base::GD->new (-width => 20,
                                                    -height => 10);
  $image->rectangle (0,0, 19,9, '#000000', 1);
  $image->rectangle (0,0, 2,2, '#FFFFFF', 1);
  is ($image->xy (0,0), '#FFFFFF');
  is ($image->xy (1,1), '#FFFFFF');
  is ($image->xy (2,1), '#FFFFFF');
  is ($image->xy (3,3), '#000000');
}

#------------------------------------------------------------------------------
# transparent

{
  my $image = Image::Base::GD->new (-width => 20,
                                    -height => 10);
  $image->rectangle (0,0, 19,9, 'None', 1);
}

#------------------------------------------------------------------------------
# get('-file')

{
  my $image = Image::Base::GD->new (-width => 10,
                                    -height => 10);
  is (scalar ($image->get ('-file')), undef);
  is_deeply  ([$image->get ('-file')], [undef]);
}

#------------------------------------------------------------------------------
# add_colours

foreach my $truecolor (1,0) {

  GD::Image->trueColor(0);
  my $image = Image::Base::GD->new (-width  => 100,
                                    -height => 100,
                                    -truecolor => $truecolor);
  diag "isTrueColor: ",$image->get('-gd')->isTrueColor;
  $image->get('-gd')->alphaBlending(0);
  $image->add_colours ('#FF00FF', 'None', '#FFAAAA');

  $image->xy (72,72, '#FF00FF');
  is ($image->xy (72,72), '#FF00FF',
      'add_colours() fetch #FF00FF');

  $image->xy (51,51, '#FFAAAA');
  is ($image->xy (51,51), '#FFAAAA',
      'add_colours() fetch #FFAAAA');

  $image->xy (60,60, 'None');
  is ($image->xy (60,60), 'None',
      'add_colours() fetch transparent');
}

exit 0;
