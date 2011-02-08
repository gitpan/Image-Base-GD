#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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

use 5.006;
use strict;
use warnings;

use Smart::Comments;

{
  require Image::Base::GD;
  my $gd = Image::Base::GD->new (-width => 10, -height => 10);
  $gd->rectangle (0,0, 9,9, 'black');
  $gd->rectangle (3,3, 7,7, '#FFFF0000FFFF');

  exit 0;
}
