require 'prawn'
require 'set'

class Chord

  attr_accessor :name, :base_fret, :frets_shown, :strings, :fingering

  def initialize( name, base_fret, frets_shown, strings, fingering )
    @name = name
    @base_fret = base_fret
    @frets_shown = frets_shown
    @strings = strings
    @fingering = fingering
  end
end

$chord_library = { 'Am' => Chord.new( 'Am', 0, 4, [ 2, 0, 0, 0 ], '2000' ),
                   'C'  => Chord.new( 'C', 2, 4, [ -1, 0, 0, 3 ], '0003' ),
                   'D7' => Chord.new( 'D7', 0, 4, [ 2, 0, 2, 0 ], '1030' ),
                   'Em' => Chord.new( 'Em', 0, 4, [ 0, 4, 3, 2 ], '0321' ),
                   'F'  => Chord.new( 'F', 0, 4, [ 2, 0, 1, 0 ], '2010' ),
                   'Fm' => Chord.new( 'Fm', 0, 4, [ 1, 0, 1, 3 ], '1024' ),
                   'G'  => Chord.new( 'G', 0, 4, [ 0, 2, 3, 2 ], '0132' ),
                   'G7' => Chord.new( 'G7', 0, 4, [ 0, 2, 1, 2 ], '0213' )
}

def draw_chord( chord_name, x, y )

  chord = $chord_library[chord_name]

  name_height = $pdf.height_of( 'C', :size => 12, :style => :bold )

  $pdf.bounding_box( [x,y], :width => 30, :height => ( name_height + 36 )) do
    #$pdf.stroke_bounds
    $pdf.text chord.name, :align => :center, :size => 12, :style => :bold
    $pdf.stroke do
      $pdf.rectangle [6, 36], 18, 24
      $pdf.vertical_line 12, 36, :at => 12
      $pdf.vertical_line 12, 36, :at => 18
      $pdf.horizontal_line 6, 24, :at => 18
      $pdf.horizontal_line 6, 24, :at => 24
      $pdf.horizontal_line 6, 24, :at => 30
    end

    if chord.base_fret > 0
      $pdf.draw_text chord.base_fret, :at => [26, 33], :size => 6
    end

    string_x = 6
    chord.strings.each do |fret|
      if fret == -1
        $pdf.stroke_line [string_x - 2, 37], [string_x + 2, 41]
        $pdf.stroke_line [string_x + 2, 37], [string_x - 2, 41]
      elsif fret == 0
        $pdf.stroke_circle [string_x, 39], 2
      else
        $pdf.fill_circle [string_x, 39 - ( fret - chord.base_fret ) * 6 ], 2
        $pdf.stroke
      end
      string_x += 6
    end

    string_x = 6
    chord.fingering.each_char do |finger|
      if finger != '0'
        $pdf.draw_text finger, :at => [string_x - 2, 6], :size => 6
      end
      string_x += 6
    end
  end
end

input_file = ARGV[0]
output_file = ARGV[1]
chord_pro = open( input_file ).read

chords = Set.new
chord_pro.scan( /\[[^\]]+\]/ ) do |chord|
  #print "#{chord}\n"
  chord_name = chord[1..(chord.size - 2)]
  chord_name = chord.match( /[^\[\]\*]+/ )[0]
  #print "#{chord_name}\n"
  chords.add chord_name
end

$pdf = Prawn::Document.new


chord_pro.each_line do |line|

  line.strip!
  default_print = true

  if line =~ /\{title:.*\}/
    # this line contains the song title
    print "Found the title: ---#{line}---\n"
    tokens = /^(?<leader>[^\{\}]*)\{title:(?<title>[^\}]*)\}(?<trailer>.*)$/.match line
    leader, title, trailer = tokens.captures
    #print "Tokens:---#{tokens.captures}---\n"
    if !leader.strip.empty?
      $pdf.text leader
    end

    $pdf.text title.strip, :align => :center, :size => 18, :style => :bold, :color => '00FF00'

    if !trailer.strip.empty?
      $pdf.text trailer
    end
    default_print = false
  end

  if line =~ /\{subtitle:.*\}/
    # this line generally contains the composer or performer
    #print "Found the subtitle: ---#{line}---\n"
    tokens = /^(?<leader>[^\{\}]*)\{subtitle:(?<subtitle>[^\}]*)\}(?<trailer>.*)$/.match line
    leader, subtitle, trailer = tokens.captures
    #print "Tokens:---#{tokens.captures}---\n"
    if !leader.strip.empty?
      $pdf.text leader
    end

    $pdf.text subtitle.strip, :align => :center, :size => 14, :style => :italic

    if !trailer.strip.empty?
      $pdf.text trailer
    end
    default_print = false
  end

  if line =~ /\{chord-definitions\}/
    # this line indicates where we should insert the chord definitions
    #print "Found the subtitle: ---#{line}---\n"
    tokens = /^(?<leader>[^\{\}]*)\{chord-definitions\}(?<trailer>.*)$/.match line
    leader, trailer = tokens.captures
    #print "Tokens:---#{tokens.captures}---\n"
    if !leader.strip.empty?
      $pdf.text leader
    end

    chord_line = $pdf.cursor
    $pdf.bounding_box( [72, chord_line], :width => 468, :height => 50 ) do
      #$pdf.stroke_bounds

      x = 0
      chords.sort.each do |chord|
        draw_chord chord, x, 50
        x += 50
      end
    end

    if !trailer.strip.empty?
      $pdf.text trailer
    end
    default_print = false
  end

  if line =~ /\{comment:.*\}/
    # this line generally contains the composer or performer
    #print "Found the subtitle: ---#{line}---\n"
    tokens = /^(?<leader>[^\{\}]*)\{comment:(?<subtitle>[^\}]*)\}(?<trailer>.*)$/.match line
    leader, comment, trailer = tokens.captures
    #print "Tokens:---#{tokens.captures}---\n"
    if !leader.strip.empty?
      $pdf.text leader
    end

    $pdf.text comment.strip, :size => 12, :style => :bold

    if !trailer.strip.empty?
      $pdf.text trailer
    end
    default_print = false
  end

  if line =~ /\[[^\]]+\]/
    # this line contains at least one chord
    $pdf.text ' '
  end

  if default_print
    tokens = line.split /(\[[^\]]*\])/
    line_vertical_position = $pdf.cursor
    chord_vertical_position = $pdf.cursor + $pdf.height_of( 'C', :size => 12, :style => :bold )
    horizontal_position = 0
    last_token_was_chord = false
    last_token_width = 0
    tokens.each do |token|
      if !token.strip.empty?
        if token.start_with? '['
          chord_name = token.match( /[^\[\]\*]+/ )[0]
          if last_token_was_chord
            horizontal_position += last_token_width
          end
          $pdf.formatted_text_box [:text => chord_name, :color => 'FF0000'], :at => [horizontal_position, chord_vertical_position], :style => :bold, :size => 12
          last_token_was_chord = true
          last_token_width = $pdf.width_of chord_name + '  ', :style => :bold, :size => 12
        else
          width = $pdf.width_of token, :size => 12
          $pdf.text_box token, :at => [horizontal_position, line_vertical_position], :size => 12
          horizontal_position += width
          last_token_was_chord = false
        end
      end
    end
    print "#{line} --- width = #{$pdf.width_of line, :size => 12}\n"
    $pdf.text ' '

    #$pdf.text line, :size => 12
  end
end
$pdf.render_file output_file

