#!/usr/bin/perl -w

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

use 5.004;
use strict;
use warnings;

{
  require GD;
  print GD->VERSION,"\n";
  my $gd = GD::Image->new (100,100);
  foreach my $i (1 .. 259) {
    print $gd->colorAllocate(0,0,0),"\n";
  }
  exit 0;
}

{
  require GD;
  # print gdTransparent();
  print GD::gdTransparent();
  exit 0;
}

