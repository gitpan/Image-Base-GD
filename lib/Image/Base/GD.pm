# Copyright 2010 Kevin Ryde

# This file is part of Image-Base-GD.
#
# Image-Base-GD is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-GD is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-GD.  If not, see <http://www.gnu.org/licenses/>.


package Image::Base::GD;
use 5.004;
use strict;
use warnings;
use Carp;

# version 2.45 for GD::Group inst fix so GD::Simple works
# no import of gdBrushed etc constants
use GD 2.45 ();

use vars '$VERSION', '@ISA';

use Image::Base 1.09; # version 1.09 for ellipse() fixes chaining up to that
@ISA = ('Image::Base');

$VERSION = 7;

# uncomment this to run the ### lines
#use Smart::Comments '###';

sub new {
  my ($class, %params) = @_;
  ### Image-Base-GD new(): %params

  # $obj->new(...) means make a copy, with some extra settings
  if (ref $class) {
    my $self = $class;
    $class = ref $class;
    if (! defined $params{'-gd'}) {
      $params{'-gd'} = $self->get('-gd')->clone;
    }
    # inherit everything else
    %params = (%$self, %params);
    ### copy params: \%params
  }

  my $self = bless { -allocate_colours => 1,
                     -zlib_compression => -1 }, $class;
  if (! defined $params{'-gd'}) {
    my $gd;
    if (defined $params{'-file'}) {
      ### create from file: $params{'-file'}
      $gd = GD::Image->new ($params{'-file'});
    } elsif (exists $params{'-truecolor'}) {
      ### create -truecolor: !!$params{'-truecolor'}

      $gd = GD::Image->new (delete $params{'-width'},
                            delete $params{'-height'},
                            !! delete $params{'-truecolor'});
    } else {
      ### create default
      $gd = GD::Image->new (delete $params{'-width'},
                            delete $params{'-height'});
    }
    if (! $gd) {  # undef if cannot create
      croak "Cannot create GD";
    }
    $gd->alphaBlending(0);
    $self->{'-gd'} = $gd;
  }
  $self->set (%params);
  ### new made: $self
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
  ### Image-Base-GD set(): \%param

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
  #### Image-Base-GD xy: $x,$y,$colour
  my $gd = $self->{'-gd'};
  if (@_ == 4) {
    $gd->setPixel ($x, $y, $self->colour_to_index($colour));
    ### setPixel: $self->colour_to_index($colour)
  } else {
    my $pixel = $gd->getPixel ($x, $y);
    #### getPixel: $pixel
    if ($pixel == $gd->transparent) {
      #### is transparent
      return 'None';
    }
    if ($pixel >= 0x7F000000) {
      #### pixel has fully-transparent alpha 0x7F
      return 'None';
    }
    #### rgb: $gd->rgb($pixel)
    return sprintf ('#%02X%02X%02X', $gd->rgb ($pixel));
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
  # ### index: $self->colour_to_index($colour)

  # gd 2.39 draws dodgy sides on a $y1==$y2 unfilled rectangle, coming out
  # like
  #
  #     *      *
  #     ********
  #     *      *
  #
  # As a workaround use just line() instead when $y1==$y2.
  #
  my $method = ($y1 == $y2 ? 'line'  # workaround
                : $fill ? 'filledRectangle'
                : 'rectangle');
  $self->{'-gd'}->$method ($x1,$y1,$x2,$y2, $self->colour_to_index($colour));
}

sub ellipse {
  my ($self, $x1, $y1, $x2, $y2, $colour) = @_;
  ### Image-GD ellipse: "$x1, $y1, $x2, $y2, $colour"

  # If width $xw or height $yw is an odd number then GD draws the extra
  # pixel on the higher value side, ie. the centre is the rounded-down
  # position.  Hope that can be relied on ...
  #
  my $xw = $x2 - $x1;
  if (! ($xw & 1)) {
    my $yw = $y2 - $y1;
    if (! ($yw & 1)) {
      ### x centre: $x1 + $xw/2
      ### y centre: $y1 + $yw/2
      ### $xw+1
      ### $yw+1
      $self->{'-gd'}->ellipse ($x1 + $xw/2, $y1 + $yw/2,
                               $xw+1, $yw+1,
                               $self->colour_to_index($colour));
      return;
    }
  }

  ### use Image-Base
  shift->SUPER::ellipse(@_);
}

sub add_colours {
  my $self = shift;
  ### add_colours: @_

  my $gd = $self->{'-gd'};
  if ($gd->isTrueColor) {
    ### no allocation in truecolor
    return;
  }

  foreach my $colour (@_) {
    ### $colour
    if ($colour eq 'None') {
      if ($gd->transparent() != -1) {
        ### transparent already: $gd->transparent()
        next;
      }
      if ((my $index = $self->{'-gd'}->colorAllocateAlpha(0,0,0,127)) != -1) {
        $gd->transparent ($index);
        ### transparent now: $gd->transparent
        next; # successful
      }

    } else {
      my @rgb = _colour_to_rgb255($colour);
      if ($gd->colorExact(@rgb) != -1) {
        ### already exists: $gd->colorExact(@rgb)
        next;
      }
      if ($gd->colorAllocate(@rgb) != -1) {
        ### allocated
        next;
      }
    }
    croak "Cannot allocate colour: $colour";
  }
}

# not documented yet ...
sub colour_to_index {
  my ($self, $colour) = @_;
  ### Image-Base-GD colour_to_index(): $colour
  my $gd = $self->{'-gd'};

  if ($colour eq 'None') {
    if ($gd->isTrueColor) {
      ### truecolor transparent: $gd->colorAllocateAlpha(0,0,0,127)
      return $gd->colorAllocateAlpha(0,0,0,127);
    }

    # Crib note: gdImageColorExactAlpha() doesn't take the single
    # transparent() colour as equivalent to all transparents but instead
    # looks for R,G,B to match as well as the alpha.
    #
    if ((my $index = $gd->transparent) != -1) {
      ### existing palette transparent: $index
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

  my @rgb = _colour_to_rgb255($colour);
  if ($self->{'-allocate_colours'}) {
    if ((my $index = $gd->colorExact (@rgb)) != -1) {
      ### existing exact: $index
      return $index;
    }
    if ((my $index = $gd->colorAllocate (@rgb)) != -1) {
      ### allocate: $index
      return $index;
    }
  }
  ### closest: $gd->colorClosest(@rgb)
  return $gd->colorClosest (@rgb);
}

sub _colour_to_rgb255 {
  my ($colour) = @_;
  my @rgb;
  if ((@rgb = ($colour =~ /^#([0-9A-F]{2})([0-9A-F]{2})([0-9A-F]{2})$/i))
      || (@rgb = ($colour =~ /^#([0-9A-F]{2})[0-9A-F]{2}([0-9A-F]{2})[0-9A-F]{2}([0-9A-F]{2})[0-9A-F]{2}$/i))) {
    return map {hex} @rgb;
  }
  require GD::Simple;
  if (defined (my $aref = GD::Simple->color_names->{lc($colour)})) {
    ### table: $aref
    return @$aref;
  }
  croak "Unknown colour: $colour";
}

1;
__END__

=for stopwords PNG GD filename undef Ryde Zlib Zlib's truecolor RGBA

=head1 NAME

Image::Base::GD -- draw PNG format images

=head1 SYNOPSIS

 use Image::Base::GD;
 my $image = Image::Base::GD->new (-width => 100,
                                   -height => 100);
 $image->rectangle (0,0, 99,99, 'white');
 $image->xy (20,20, 'black');
 $image->line (50,50, 70,70, '#FF00FF');
 $image->line (50,50, 70,70, '#0000AAAA9999');
 $image->save ('/some/filename.png');

=head1 CLASS HIERARCHY

C<Image::Base::GD> is a subclass of C<Image::Base>,

    Image::Base
      Image::Base::GD

=head1 DESCRIPTION

C<Image::Base::GD> extends C<Image::Base> to create or update PNG format
image files using the C<GD> module and library (version 2 or higher).

The native GD drawing has lots more features, but this module is an easy way
to point C<Image::Base> style code at a GD and is a good way to get PNG out
of some C<Image::Base> code.

Colour names for drawing are taken from the C<GD::Simple> C<color_table()>,
plus hex "#RRGGBB" or "#RRRRGGGGBBBB".  Special colour "None" means
transparent.  Colours are allocated when first used.  4-digit
"#RRRRGGGGBBBB" forms are truncated to the high 2 digits since GD works in
8-bit components.

=head1 FUNCTIONS

=over 4

=item C<$image = Image::Base::GD-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  A new image can be started with
C<-width> and C<-height>,

    $image = Image::Base::GD->new (-width => 200, -height => 100);

Or an existing file can be read,

    $image = Image::Base::GD->new (-file => '/some/filename.png');

Or a C<GD::Image> object can be given,

    $image = Image::Base::GD->new (-gd => $gdimageobject);

=item C<$new_image = $image-E<gt>new (key=E<gt>value,...)>

Create and return a copy of C<$image>.  The GD within C<$image> is cloned
(per C<$gd-E<gt>clone>).  The optional parameters are applied to the new
image as per C<set>.

    # copy image, new compression level
    my $new_image = $image->new (zlib_compression => 9);

=item C<$colour = $image-E<gt>xy ($x, $y)>

=item C<$image-E<gt>xy ($x, $y, $colour)>

Get or set an individual pixel.

Currently colours returned are in hex "#RRGGBB" form, or "None" for a fully
transparent pixel.  Partly transparent pixels are returned as a colour.

=item C<$image-E<gt>rectangle ($x1,$y1, $x2,$y2, $colour, $fill)>

Draw a rectangle with corners at C<$x1>,C<$y1> and C<$x2>,C<$y2>.  If
C<$fill> is true then it's filled, otherwise just the outline.

GD library 2.0.36 has a bug when drawing 1-pixel high C<$y1 == $y2> unfilled
rectangles where it adds 3-pixel high sides to the result.
C<Image::Base::GD> has a workaround to avoid that.  The intention isn't to
second guess GD, but this fix is easy to apply and makes the output
consistent with other C<Image::Base> modules.

=item C<$image-E<gt>ellipse ($x1,$y1, $x2,$y2, $colour)>

Draw an ellipse within the rectangle bounded by C<$x1>,C<$y1> and
C<$x2>,C<$y2>.

In the current implementation ellipses with odd length sides (when
C<$x2-$x1+1> and C<$y2-$y1+1> are both odd numbers) are drawn with GD and
the rest go to C<Image::Base> since GD doesn't seem to draw even widths very
well.  This different handling is a bit inconsistent though.

=item C<$image-E<gt>add_colours ($name, $name, ...)>

Add colours to the GD palette.  Colour names are the same as to the drawing
functions.

    $image->add_colours ('red', 'green', '#FF00FF');

The drawing functions automatically add a colour if it doesn't already exist
so C<add_colours> in not needed, but it can be used to initialize the
palette with particular desired colours.

For a truecolor GD C<add_colours> does nothing since in that case each pixel
has RGBA component values, rather than an index into a palette.

=back

=head1 ATTRIBUTES

=over

=item C<-width> (integer, read-only)

=item C<-height> (integer, read-only)

The size of a GD image cannot be changed once created.

=item C<-ncolours> (integer, read-only)

The number of colours allocated in the palette, or C<undef> on a truecolor
GD (which doesn't have a palette).

This count is similar to the C<-ncolours> of C<Image::Xpm>.

=item C<-zlib_compression> (integer 0-9 or -1)

The amount of data compression to apply when saving.  The value is Zlib
style 0 for no compression up to 9 for maximum effort.  -1 means Zlib's
default level.

=item C<-gd>

The underlying C<GD::Image> object.

=back

=head1 BUGS

Putting colour "None" into pixels requires GD "alpha blending" turned off.
C<Image::Base::GD> turns off blending for GD objects it creates, but
currently if you pass in a C<-gd> then you must set the blending yourself if
you're going to use None.  Is that the best way?  The ideal might be to save
and restore while drawing None, but there's no apparent way to read the
blending setting out of a GD to later restore.  Alternately maybe turn
blending off and leave it off on first drawing any None.

=head1 SEE ALSO

L<Image::Base>,
L<GD>,
L<GD::Simple>,
L<Image::Base::PNGwriter>,
L<Image::Xpm>

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
