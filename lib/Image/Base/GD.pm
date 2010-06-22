# Copyright 2010 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.


package Image::Base::GD;
use 5.004;
use strict;
use warnings;
use Carp;
use GD ();  # no import of gdBrushed etc constants
use base 'Image::Base';

# uncomment this to run the ### lines
#use Smart::Comments;

use vars '$VERSION';
$VERSION = 1;

sub new {
  my ($class, %params) = @_;
  ### Image-Base-GD new(): %params

  my $self = bless { -allocate_colours => 1,
                     -zlib_compression => -1,
                     %params }, $class;
  if (! defined $params{'-gd'}) {
    if (defined $params{'-file'}) {
      $self->{'-gd'} = GD::Image->new ($params{'-file'});
    } else {
      $self->{'-gd'} = GD::Image->new (delete $params{'-width'},
                                       delete $params{'-height'},
                                       !! delete $params{'-truecolor'});
    }
  }
  $self->set (%params);
  return $self;
}

my %attr_to_get_method = (-width      => 'width',
                          -height     => 'height',
                          -ncolours   => 'colorsTotal',

                          # these not documented yet ...
                          -truecolor  => 'isTrueColor',
                          -interlaced => 'interlaced');
sub _get {
  my ($self, $key) = @_;
  ### Image-Base-GD _get(): $key

  if (my $method = $attr_to_get_method{$key}) {
    return $self->{'-gd'}->$method;
  }
  return $self->SUPER::_get ($key);
}

sub set {
  my ($self, %param) = @_;

  foreach my $key ('-width', '-height', '-ncolours') {
    if (exists $param{$key}) {
      croak "Attribute $key is read-only";
    }
  }

  # these not documented yet ...
  if (exists $param{'-interlaced'}) {
    $self->{'gd'}->interlaced (delete $param{'-interlaced'});
  }
  if (exists $param{'-truecolor'}) {
    my $gd = $self->{'gd'};
    if (delete $param{'-truecolor'}) {
      if (! $gd->isTrueColor) {
        die "How to turn palette into truecolor?"
      }
    } else {
      if ($gd->isTrueColor) {
        $gd->trueColorToPalette;
      }
    }
  }

  %$self = (%$self, %param);
}

sub load {
  my ($self, $filename) = @_;
  if (@_ == 1) {
    $filename = $self->get('-file');
  } else {
    $self->set('-file', $filename);
  }
  $self->{'-gd'} = GD::Image->newFromPng ($filename);
}

sub save {
  my ($self, $filename) = @_;
  ### Image-Base-GD save(): @_
  if (@_ == 2) {
    $self->set('-file', $filename);
  } else {
    $filename = $self->get('-file');
  }
  ### $filename
  my $data = $self->{'-gd'}->png ($self->get('-zlib_compression'));

  # or maybe File::Slurp::write_file($filename,{binmode=>':raw'})
  my $fh;
  (open $fh, ">$filename"
   and binmode($fh)
   and print $fh $data
   and close $fh)
    or croak "Cannot write file $filename: $!";
}

sub xy {
  my ($self, $x, $y, $colour) = @_;
  # ### Image-Base-GD xy: @_
  my $gd = $self->{'-gd'};
  if (@_ == 4) {
    $gd->setPixel ($self->colour_to_index($colour), $x, $y);
  } else {
    return sprintf ('#%02X%02X%02X', $gd->rgb ($gd->getPixel ($x, $y)));
  }
}
sub line {
  my ($self, $x1, $y1, $x2, $y2, $colour) = @_;
  ### Image-Base-GD line: @_
  $self->{'-gd'}->line ($x1,$y1,$x2,$y2, $self->colour_to_index($colour));
}
sub rectangle {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Image-Base-GD rectangle: @_
  my $method = ($fill ? 'filledRectangle' : 'rectangle');
  ### index: $self->colour_to_index($colour)
  $self->{'-gd'}->$method ($x1,$y1,$x2,$y2, $self->colour_to_index($colour));
}
sub ellipse {
  my ($self, $x1, $y1, $x2, $y2, $colour) = @_;
  ### Image-GD ellipse: "$x1, $y1, $x2, $y2, $colour"
  $self->{'-gd'}->ellipse ($x1, $y1,
                           $x2-$x1+1, $y2-$y1+1,
                           $self->colour_to_index($colour));
}

# not documented yet ...
sub colour_to_index {
  my ($self, $colour) = @_;
  ### Image-Base-GD colour_to_index(): $colour
  my $gd = $self->{'-gd'};

  if ($colour eq 'None') {
    if ((my $index = $gd->transparent) != -1) {
      return $index;
    }
    if (! $self->{'-allocate_colours'}) {
      croak "No transparent index set";
    }
    if ((my $index = $self->{'-gd'}->colorAllocate(0,0,0)) != -1) {
      $gd->transparent ($index);
      ### transparent now: $gd->transparent
      return $index;
    }
    croak "No colour cells free to create transparent";
  }

  my ($r,$g,$b);
  if (($r,$g,$b) = ($colour =~ /^#([0-9A-F]{2})([0-9A-F]{2})([0-9A-F]{2})$/i)){
    $r = hex($r);
    $g = hex($g);
    $b = hex($b);
  } else {
    require GD::Simple;
    if (defined (my $aref = GD::Simple->color_names->{lc($colour)})) {
      ### table: $aref
      ($r,$g,$b) = @$aref;
    } else {
      croak "Unknown colour: $colour";
    }
  }

  if ($self->{'-allocate_colours'}) {
    if ((my $index = $gd->colorExact ($r, $g, $b)) != -1) {
      return $index;
    }
    if ((my $index = $gd->colorAllocate ($r, $g, $b)) != -1) {
      return $index;
    }
  }
  return $gd->colorClosest ($r, $g, $b);
}

1;
__END__

=for stopwords PNG GD filename undef Ryde Zlib

=head1 NAME

Image::Base::GD -- draw PNG format images

=head1 SYNOPSIS

 use Image::Base::GD;
 my $image = Image::Base::GD->new (-width => 100,
                                   -height => 100);
 $image->rectangle (0,0, 99,99, 'white');
 $image->line (50,50, 70,70, '#FF00FF');
 $image->save ('/some/filename.png');

=head1 CLASS HIERARCHY

C<Image::Base::GD> is a subclass of C<Image::Base>,

    Image::Base
      Image::Base::GD

=head1 DESCRIPTION

C<Image::Base::GD> extends C<Image::Base> to create or update PNG
format image files using the C<GD> module and library.

Colour names are taken from the C<GD::Simple> C<color_table>, plus hex
"#RRGGBB".  The special colour "None" means transparent.  Colours are
allocated when first used.

=head1 FUNCTIONS

=over 4

=item C<$image = Image::Base::GD-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  A new image can be start with
C<-width> and C<-height>,

    $image = Image::Base::GD->new (-width => 200, -height => 100);

Or an existing file can be read,

    $image = Image::Base::GD->new (-file => '/some/filename.png');

Or a C<GD::Image> object can be used,

    $image = Image::Base::GD->new (-gd => $gdimageobject);

=back

=head1 ATTRIBUTES

=over

=item C<-width> (integer, read-only)

=item C<-height> (integer, read-only)

The size of a GD image cannot be changed once created.

=item C<-ncolours> (integer, read-only)

The number of colours allocated in the palette, or C<undef> on a truecolor
GD (since it doesn't have a palette).

This colour count is similar to the C<-ncolours> of C<Image::Xpm>.

=item C<-zlib_compression> (integer 0-9 or -1)

The amount of data compression to apply when saving.  The value is Zlib
style 0 for no compression up to 9 for maximum effort.  -1 means Zlib's
default level.

=item C<-gd>

The underlying C<GD::Image> object.

=back

=head1 SEE ALSO

L<Image::Base>,
L<Image::Base::PNGwriter>,
L<GD>,
C<Image::Xpm>

=head1 HOME PAGE

http://user42.tuxfamily.org/image-base-gd/index.html

=head1 LICENSE

Image-Base-GD is Copyright 2010 Kevin Ryde

Image-Base-GD is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Image-Base-GD is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Image-Base-GD.  If not, see <http://www.gnu.org/licenses/>.

=cut
