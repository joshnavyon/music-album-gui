require "rubygems"
require "gosu"
require "fileutils"

# --------------------------#
#       Global Constant     #
# --------------------------#
BG_COLOR = Gosu::Color.rgb(212, 208, 202)
WHITE_COLOR = Gosu::Color::WHITE
BLACK_COLOR = Gosu::Color::BLACK
GRAY_COLOR = Gosu::Color::GRAY

WIN_WIDTH = 470
WIN_HEIGHT = 700

# --------------------------#
#          Modules          #
# --------------------------#
module Img
  BACK, MUTE, SOUND, PLAY, PAUSE, FWD, PREV, PLIST, DEL, DELON, DELNOW = *0..10
end

module ZOrder
  BACKGROUND, UI, BTN = *0..2
end

module Genre
  POP, CLASSIC, JAZZ, ROCK = *1..4
end

# --------------------------#
#          Classes          #
# --------------------------#
class Image
  attr_accessor :name, :x, :y, :z, :size, :width, :height

  def initialize(name, x, y, z, size, width, height)
    @name = name
    @x = x
    @y = y
    @z = z
    @size = size
    @width = width
    @height = height
  end
end

class Album
  attr_accessor :artwork, :artist, :title, :release_date, :genre, :tracks

  def initialize(artwork, artist, title, release_date, genre, tracks)
    @artwork = artwork
    @artist = artist
    @title = title
    @release_date = release_date
    @genre = genre
    @tracks = tracks
  end
end

class Track
  attr_accessor :name, :location

  def initialize(name, loc)
    @name = name
    @location = loc
  end
end

class Playlist
  attr_accessor :artwork, :artist, :title, :release_date, :genre, :tracks

  def initialize(artwork, artist, title, release_date, genre, tracks)
    @artwork = artwork
    @artist = artist
    @title = title
    @release_date = release_date
    @genre = genre
    @tracks = tracks
  end
end

class MusicPlayerMain < Gosu::Window
  def initialize
    super(WIN_WIDTH, WIN_HEIGHT, false)
    self.caption = "Music Player"

    #Textbox size
    @textbox_x = 50
    @textbox_y = 100

    #Fonts
    @font_light = Gosu::Font.new(25, name: "fonts/SairaCondensed-Light.ttf")
    @font_regular = Gosu::Font.new(25, name: "fonts/SairaCondensed-Medium.ttf")
    @font_bold = Gosu::Font.new(45, name: "fonts/BebasNeue-Regular.ttf")
    @font_textbox = Gosu::Font.new(30, name: "fonts/SairaCondensed-Medium.ttf")

    # Initialize @images = Image()
    @images = init_images
    # Intialize textbox
    @text_fields = Gosu::TextInput.new()

    # Initialize settings
    @page = -1
    @volume = 0.3
    @xpos, @ypos, @gap, @ystart, @font_start = 60, 460, 20, 145, 5
    @array = @playlists = Array.new
    @sound = true
    @delete = false
    @tracks_clicked = @albums_deleted = nil
  end

  # --------------------------#
  #         Functions         #
  # --------------------------#
  def draw_textbox(x, y, z)
    font = Gosu::Font.new(20)
    height = font.height
    width = 350
    padding = 5

    inactive_color = 0xcc_666666
    active_color = 0xcc_000000
    selection_color = 0xcc_0000ff
    caret_color = 0xff_ffffff

    # Change the background colour if this is the currently selected text field.
    if self.text_input == @text_fields
      color = active_color
    else
      color = inactive_color
    end

    Gosu.draw_rect(x - padding, y - padding, width + 2 * padding, height + 2 * padding, color, z)

    # Calculate the position of the caret.
    pos_x = x + @font_textbox.text_width(@text_fields.text[0...@text_fields.caret_pos])

    # Draw the caret if this is the currently selected field.
    if self.text_input == @text_fields
      Gosu.draw_line(pos_x, y, caret_color, pos_x, y + height, caret_color, z)
    end

    # Draw the textbox text
    @font_textbox.draw_text(@text_fields.text, x, y - 5, z)
  end

  def move_caret(x)
    # Test character by character
    1.upto(@text_fields.text.length) do |i|
      if mouse_x < x + @font_textbox.text_width(@text_fields.text[0...i])
        @text_fields.caret_pos = @text_fields.selection_start = i - 1
        return
      end
    end
    # Default case: move caret to text length
    @text_fields.caret_pos = @text_fields.selection_start = @text_fields.text.length
  end

  def init_images()
    back_btn = Gosu::Image.new("images/home.png")
    mute_btn = Gosu::Image.new("images/mute.png")
    sound_btn = Gosu::Image.new("images/sound.png")
    pause_btn = Gosu::Image.new("images/pause.png")
    play_btn = Gosu::Image.new("images/play.png")
    forward_btn = Gosu::Image.new("images/forward.png")
    previous_btn = Gosu::Image.new("images/previous.png")
    playlist_btn = Gosu::Image.new("images/add_playlist.png")
    delete_btn = Gosu::Image.new("images/delete.png")
    deleteon_btn = Gosu::Image.new("images/delete_on.png")
    deletenow_btn = Gosu::Image.new("images/delete_now.png")

    images = []
    play_size = 0.1
    del_size = 0.06
    home_size = 0.05
    plist_size = 0.15

    # Set the image data [name, x, y, z, rot, scale, size_x, size_y]
    img_data = [
      [
        back_btn,
        25,
        25,
        ZOrder::BTN,
        home_size,
        back_btn.width * home_size,
        back_btn.height * home_size,
      ],
      [
        mute_btn,
        440,
        25,
        ZOrder::BTN,
        home_size,
        mute_btn.width * home_size,
        mute_btn.height * home_size,
      ],
      [
        sound_btn,
        440,
        25,
        ZOrder::BTN,
        home_size,
        sound_btn.width * home_size,
        sound_btn.height * home_size,
      ],
      [
        play_btn,
        WIN_WIDTH / 2,
        WIN_HEIGHT - 27,
        ZOrder::BTN,
        play_size,
        play_btn.width * play_size,
        play_btn.height * play_size,
      ],
      [
        pause_btn,
        WIN_WIDTH / 2,
        WIN_HEIGHT - 27,
        ZOrder::BTN,
        play_size,
        pause_btn.width * play_size,
        pause_btn.height * play_size,
      ],
      [
        forward_btn,
        WIN_WIDTH / 2 + 100,
        WIN_HEIGHT - 27,
        ZOrder::BTN,
        play_size,
        forward_btn.width * play_size,
        forward_btn.height * play_size,
      ],
      [
        previous_btn,
        WIN_WIDTH / 2 - 100,
        WIN_HEIGHT - 27,
        ZOrder::BTN,
        play_size,
        previous_btn.width * play_size,
        previous_btn.height * play_size,
      ],
      [
        playlist_btn,
        WIN_WIDTH - 40,
        WIN_HEIGHT - 28,
        ZOrder::BTN,
        plist_size,
        playlist_btn.width * plist_size,
        playlist_btn.height * plist_size,
      ],
      [
        delete_btn,
        440,
        25,
        ZOrder::BTN,
        del_size,
        delete_btn.width * home_size,
        delete_btn.height * home_size,
      ],
      [
        deleteon_btn,
        440,
        25,
        ZOrder::BTN,
        del_size,
        deleteon_btn.width * home_size,
        deleteon_btn.height * home_size,
      ],
      [
        deletenow_btn,
        WIN_WIDTH - 28,
        WIN_HEIGHT - 28,
        ZOrder::BTN,
        del_size,
        deleteon_btn.width * home_size,
        deleteon_btn.height * home_size,
      ],
    ]

    # assign attr: name, x, y, z, rot, centre_x, centre_y, size_x, size_y
    img_data.each_with_index do |element, i|
      img_data =
        Image.new(
          element[0],
          element[1],
          element[2],
          element[3],
          element[4],
          element[5],
          element[6],
        )

      images[i] = img_data
    end
    return images
  end

  def draw_image(img)
    @images[img].name.draw_rot(
      @images[img].x,
      @images[img].y,
      @images[img].z,
      0,
      0.5,
      0.5,
      @images[img].size,
      @images[img].size,
    )
  end

  # Detects if a 'mouse sensitive' area has been hovered on
  def area_hovered(topY, area)
    if area == :albums
      n = @albums.length
    elsif area == :tracks
      n = @albums[@selected_album].tracks.length
    elsif area == :playlist
      n = 0
      @albums.each do |album|
        album.tracks.each { |track| n += 1 } if album.artist.chomp != "Author"
      end
    end

    if (mouse_x > 0 and mouse_x < WIN_WIDTH) && (mouse_y >= topY && mouse_y < topY + @gap * n)
      n.times do |album|
        return album if (mouse_y >= topY + album * @gap && mouse_y < topY + album * @gap + @gap)
      end
    end
  end

  # Detects if a 'given area' is clicked
  def area_clicked?(posX, posY, widthX, heightY)
    (mouse_x >= posX && mouse_x < widthX && mouse_y >= posY && mouse_y < heightY) ? true : false
  end

  # Put in your code here to load albums and tracks
  def read_albums(music_file, plist = false)
    index = 0
    if plist == false
      count = music_file.gets.to_i
    else
      read_album(music_file)
      return
    end

    albums = Array.new

    while index < count
      album = read_album(music_file)
      albums << album
      index += 1
    end

    return albums
  end

  def read_album(music_file)
    album_cover = music_file.gets.chomp
    album_artist = music_file.gets.chomp
    album_title = music_file.gets.chomp
    album_date = music_file.gets.chomp
    album_genre = music_file.gets.chomp
    album_tracks = read_tracks(music_file)

    Album.new(album_cover, album_artist, album_title, album_date, album_genre, album_tracks)
  end

  def read_tracks(music_file)
    count = music_file.gets.to_i()
    index = 0

    tracks = Array.new
    while index < count
      track = read_track(music_file)
      tracks << track
      index += 1
    end
    return tracks
  end

  def read_track(music_file)
    name = music_file.gets
    loc = music_file.gets

    Track.new(name, loc)
  end

  # Draws the cover for the albums
  def draw_albums()
    img = Gosu::Image.new(@albums[@selected_album].artwork)
    img.draw_rot(WIN_WIDTH / 2, 240, ZOrder::UI, 0, 0.5, 0.5, 0.67, 0.67)
    Gosu.draw_rect(63, 66, 350, 385, GRAY_COLOR, ZOrder::BACKGROUND)
    Gosu.draw_rect(60, 63, 350, 385, WHITE_COLOR, ZOrder::BACKGROUND)
  end

  # Display the UI for the Albums:
  def display_album()
    xpos = WIN_WIDTH / 2
    ypos = @ypos - 50
    release_y = ypos + 10
    text_width = @font_bold.text_width(@albums[@selected_album].artist, 1)
    title_gap = xpos + (text_width * 1.11) / 2

    #Print title and release_date
    @font_bold.draw_text_rel(
      @albums[@selected_album].artist,
      xpos,
      ypos,
      ZOrder::UI,
      0.5,
      0,
      1.1,
      1.0,
      BLACK_COLOR,
    )
    @font_light.draw_text(
      @albums[@selected_album].release_date,
      title_gap,
      release_y,
      ZOrder::UI,
      1.1,
      1.3,
      BLACK_COLOR,
    )

    #Print tracks
    display_tracks
  end

  # Display {n} number of tracks
  def display_tracks()
    n = @albums[@selected_album].tracks.length
    xpos = @xpos
    ypos = @ypos
    index = 0

    while index < n
      track_access = @albums[@selected_album].tracks[index]
      display_track(track_access.name, xpos, ypos)

      ypos += @gap
      index += 1
    end
  end

  def display_track(name, xpos, ypos)
    @font_regular.draw_text(name, xpos, ypos, ZOrder::UI, 1.0, 1.2, BLACK_COLOR)
  end

  # Takes a track index and an Album and plays the Track from the Album
  def playTrack(index)
    if (index % @albums[@selected_album].tracks.length) == 0
      index = 0
    elsif index < 0
      index = @albums[@selected_album].tracks.length - 1
    end
    @song = Gosu::Song.new(@albums[@selected_album].tracks[index].location.chomp)
    @song.play(false)
    @play = true
    # @song.play(false) unless @song.pause()
    @song.volume = @volume unless @song.volume == 0

    @song_play, @song_id = true, index
  end

  # Draw - Background
  def draw_background
    Gosu.draw_rect(0, 0, WIN_WIDTH, 50, BLACK_COLOR, ZOrder::UI)
    Gosu.draw_rect(0, WIN_HEIGHT - 55, WIN_WIDTH, 55, BLACK_COLOR, ZOrder::UI)
    Gosu.draw_rect(0, 0, WIN_WIDTH, WIN_HEIGHT, BG_COLOR, ZOrder::BACKGROUND, mode = :default)
    draw_menu
  end

  # Draw - Top menu bar
  def draw_menu()
    @font_bold.draw_text_rel("BUSSIN'", WIN_WIDTH / 2, 27, ZOrder::UI, 0.5, 0.5, 1.1, 1.0, BG_COLOR)

    # Home button
    draw_image(Img::BACK)
  end

  # Display - Albums
  def draw_albums_ui(ypos, count, index)
    while index < count
      @font_regular.draw_text(
        "> #{@albums[index].title.chomp} - #{@albums[index].artist.chomp}",
        @xpos,
        ypos + 20 * index,
        ZOrder::UI,
        1.0,
        1.2,
        BLACK_COLOR,
      )
      index += 1
    end

    # Hover effect for Albums
    if i = area_hovered(@ystart, :albums)
      Gosu.draw_rect(0, ypos + @font_start + @gap * i, WIN_WIDTH, @gap, BLACK_COLOR, ZOrder::UI)
      @font_regular.draw_text(
        "> #{@albums[i].title.chomp} - #{@albums[i].artist.chomp}",
        @xpos,
        @ystart + @gap * i,
        ZOrder::UI,
        1.0,
        1.2,
        BG_COLOR,
      )
    end

    # Draw - Add playlist
    @font_regular.draw_text(
      "> Add playlist",
      @xpos,
      ypos + @gap * count,
      ZOrder::UI,
      1.0,
      1.2,
      BLACK_COLOR,
    )

    # Hover effect for Playlist
    if area_clicked?(0, ypos + @font_start + @gap * count, WIN_WIDTH, ypos + @font_start + @gap * count + @gap)
      Gosu.draw_rect(0, ypos + @font_start + @gap * count, WIN_WIDTH, @gap, BLACK_COLOR, ZOrder::UI)
      @font_regular.draw_text(
        "> Add playlist",
        @xpos,
        ypos + @gap * count,
        ZOrder::UI,
        1.0,
        1.2,
        BG_COLOR,
      )
    end
  end

  # --------------------------#
  #    Inherited Functions    #
  # --------------------------#
  def update
    # Play the next song when the song ends.
    if @play
      while !@song.playing?
        @song_id += 1
        sleep(0.3)
        playTrack(@song_id)

        # Draw the tracks_UI indicator
        @next_song = true
      end
    end
  end

  # Draws GUI based on @page
  def draw
    # Show x and y cursor pos:
    # @font_light.draw_text(
    #   "mouse_x: #{mouse_x}",
    #   @xpos,
    #   580,
    #   ZOrder::UI,
    #   1.1,
    #   1.3,
    #   BLACK_COLOR,
    # )
    # @font_light.draw_text(
    #   "mouse_y: #{mouse_y}",
    #   @xpos,
    #   600,
    #   ZOrder::UI,
    #   1.1,
    #   1.3,
    #   BLACK_COLOR,
    # )

    case @page
    when -1 # Initial Page.
      draw_background
      draw_textbox(@textbox_x, @textbox_y, 0)
      @font_regular.draw_text("Enter file: ", 50, 70, ZOrder::UI, 1.0, 1.2, BLACK_COLOR)
    when 0 # File doesnt exists - Page.
      draw_background
      draw_textbox(@textbox_x, @textbox_y, 0)
      # @text_fields.draw(0)
      @font_regular.draw_text("Enter file: ", 50, 70, ZOrder::UI, 1.0, 1.2, BLACK_COLOR)
      @font_regular.draw_text_rel(
        "Error: No File '#{@file_name}'!",
        WIN_WIDTH / 2,
        150,
        ZOrder::UI,
        0.5,
        0.5,
        1.1,
        1.0,
        BLACK_COLOR,
      )
    when 1 # Select Albums - Page.
      draw_background
      draw_textbox(@textbox_x, @textbox_y, 0)
      @font_regular.draw_text("Enter file: ", 50, 70, ZOrder::UI, 1.0, 1.2, BLACK_COLOR)
      count = @albums.length
      draw_albums_ui(@ystart, count, 0)

      if @delete
        draw_image(Img::DELON)
        draw_image(Img::DELNOW)
      else
        draw_image(Img::DEL)
      end
      if @albums_deleted != nil && @delete
        @albums_deleted.count.times do |x|
          Gosu.draw_rect(
            0,
            @ystart + @gap * @albums_deleted[x],
            WIN_WIDTH,
            @gap,
            BLACK_COLOR,
            ZOrder::UI,
          )
          @font_regular.draw_text(
            "> #{@albums[@albums_deleted[x]].title.chomp} - #{@albums[@albums_deleted[x]].artist.chomp}",
            @xpos,
            @ystart - @font_start + @gap * @albums_deleted[x],
            ZOrder::UI,
            1.0,
            1.2,
            BG_COLOR,
          )
        end
      end
    when 2 # Select tracks - Page.
      track_access = @albums[@selected_album].tracks

      draw_background
      draw_albums
      display_album

      if @pressed
        draw_image(Img::FWD)
        draw_image(Img::PREV)
        @sound ? draw_image(Img::SOUND) : draw_image(Img::MUTE)
        @play ? draw_image(Img::PAUSE) : draw_image(Img::PLAY)
      end

      if i = area_hovered(@ypos + @font_start, :tracks)
        Gosu.draw_rect(0, @ypos + @font_start + @gap * i, WIN_WIDTH, @gap, BLACK_COLOR, ZOrder::UI)
        @font_regular.draw_text(
          track_access[i].name,
          @xpos,
          @ypos + @gap * i,
          ZOrder::UI,
          1.0,
          1.2,
          BG_COLOR,
        )
      end

      if (@pressed || @next_song)
        Gosu.draw_rect(0, @ypos + @font_start + @gap * @song_id, WIN_WIDTH, @gap, BLACK_COLOR, ZOrder::UI)
        @font_regular.draw_text(
          track_access[@song_id].name,
          @xpos,
          @ypos + @gap * @song_id,
          ZOrder::UI,
          1.0,
          1.2,
          BG_COLOR,
        )
      end
    when 3 # Select Playlist - Page.
      draw_background
      x = 0

      count = @full_tracks.length
      @font_regular.draw_text("Select tracks:", @xpos, 70, ZOrder::UI, 1.0, 1.2, BLACK_COLOR)
      while x < count
        @font_regular.draw_text(
          "> #{@full_tracks[x].name}",
          @xpos,
          105 + @gap * x,
          ZOrder::UI,
          1.0,
          1.2,
          BLACK_COLOR,
        )
        x += 1
      end

      if i = area_hovered(110, :playlist)
        Gosu.draw_rect(0, 110 + @gap * i, WIN_WIDTH, @gap, BLACK_COLOR, ZOrder::UI)
        @font_regular.draw_text(
          "> #{@full_tracks[i].name}",
          @xpos,
          105 + @gap * i,
          ZOrder::UI,
          1.0,
          1.2,
          BG_COLOR,
        )
      end

      if @tracks_clicked != nil
        @tracks_clicked.count.times do |x|
          Gosu.draw_rect(
            0,
            110 + @gap * @tracks_clicked[x],
            WIN_WIDTH,
            @gap,
            BLACK_COLOR,
            ZOrder::UI,
          )
          @font_regular.draw_text(
            "> #{@full_tracks[@tracks_clicked[x]].name}",
            @xpos,
            105 + @gap * @tracks_clicked[x],
            ZOrder::UI,
            1.0,
            1.2,
            BG_COLOR,
          )
        end
      end

      draw_image(Img::PLIST)
    end
  end

  def needs_cursor?
    true
  end

  def button_down(id)
    if id == Gosu::KbEnter || id == Gosu::KbReturn # Enter album by name - Enter/Return
      # File name = text inputted by usr
      @file_name = @text_fields.text

      i = 0
      @full_tracks = []
      if File.exist?(@file_name)
        music_file = File.new(@file_name, "r")
        @albums = read_albums(music_file)
        @albums.each do |album|
          if album.artist != "Author"
            album.tracks.each do |track|
              @full_tracks[i] = track
              i += 1
            end
          end
        end

        # puts "found file!"
        @file_exists = true
        @page = 1
        music_file.close
      else
        @file_exists = @pressed = false
        @page = 0
      end
    end

    if id == Gosu::MsLeft
      if area_clicked?(
           @images[Img::BACK].x - @images[Img::BACK].width,
           @images[Img::BACK].y - @images[Img::BACK].height,
           @images[Img::BACK].x + @images[Img::BACK].width,
           @images[Img::BACK].y + @images[Img::BACK].height,
         ) # Menu - MsLeft
        if @pressed
          @song.stop
          @pressed = false
        end
        @array = @tracks_clicked = @albums_deleted = Array.new()
        @play = @next_song = false
        if @file_exists
          @page = 1
        elsif @file_exists
          @page = 0
        else
          @page = -1
        end
      elsif area_clicked?(@textbox_x, @textbox_y, 350, 130) # Textbox - MsLeft
        self.text_input = @text_fields
        # Move caret to clicked position
        move_caret(@textbox_x) unless self.text_input.nil?
      elsif @page == 1 # Page 1 - MsLeft
        if i = area_hovered(@ystart, :albums)
          @array << i
          @albums_deleted = @array.uniq
        end

        # Area - Delete
        if area_clicked?(
             @images[Img::DEL].x - @images[Img::DEL].width,
             @images[Img::DEL].y - @images[Img::DEL].height,
             @images[Img::DEL].x + @images[Img::DEL].width,
             @images[Img::DEL].y + @images[Img::DEL].height,
           )
          if @delete
            @delete = false
          else
            @delete = true
            @array = @albums_deleted = Array.new
          end
        end

        count = @albums.length
        # Delete albums in range specified by usrs
        if area_clicked?(
             @images[Img::DELNOW].x - @images[Img::DELNOW].width,
             @images[Img::DELNOW].y - @images[Img::DELNOW].height,
             @images[Img::DELNOW].x + @images[Img::DELNOW].width,
             @images[Img::DELNOW].y + @images[Img::DELNOW].height,
           ) && !@albums_deleted.nil?
          for i in 0...@albums_deleted.count
            count -= 1

            @albums_deleted = @albums_deleted.sort

            del_index = @albums_deleted.shift()
            # puts "Deleting #{del_index}"
            @albums_deleted = @albums_deleted.collect() { |x| x.zero? ? x = 0 : x - 1 }

            File.write("albums.txt", del_index, mode: "r+") # Replace count to delete index
            f_read = File.new("albums.txt", "r")

            # Get line_start for playlist
            read_albums(f_read) # Read from deleted (start)
            p_start = f_read.lineno

            # Get line_end for playlist
            read_albums(f_read, true) # Read until deleted (end)
            p_end = f_read.lineno
            # puts "Deleting line: #{p_start} - #{p_end}"

            File.write("albums.txt", count, mode: "r+") # Replace index with now_count
            f_read.rewind # Set read pointer to 0
            f_write = File.new("albums.txt.tmp", "w") # Create temp files to write

            # Loop through all lines, and write it to temp, unless line is in the range of playlist
            f_read.each_line do |line|
              unless $. == p_start && del_index == count
                f_write.write(line) unless $. > p_start and $. <= p_end
              else
                f_write.write(line.chomp)
              end
            end

            f_write.close()
            f_read.close() # Close the file
            FileUtils.mv "albums.txt.tmp", "albums.txt" # Replace original files with temp files.
          end

          # Reloads the file and page
          music_file = File.new(@file_name, "r")
          @albums = read_albums(music_file)
          @array = @albums_deleted = Array.new
          @delete = false

          @page = 1
        end

        # Album lists - Btn
        if !@delete
          if n = area_hovered(@ystart, :albums)
            @selected_album = n
            @albums_clicked, @check_file = true, false
            @page = 2
          end
        end

        # > Add Playlist - Btn
        if area_clicked?(
             0,
             @ystart + @gap * @albums.length,
             WIN_WIDTH,
             @ystart + @gap * @albums.length + @gap,
           )
          @array = Array.new
          @page = 3
        end
      elsif @page == 2 # Page 2 - MsLeft
        if i = area_hovered(@ypos + @font_start, :tracks)
          @pressed = true
          sleep(0.2)
          playTrack(i)
        end
        # Mute area
        if area_clicked?(
             @images[Img::MUTE].x - @images[Img::MUTE].width,
             @images[Img::MUTE].y - @images[Img::MUTE].height,
             @images[Img::MUTE].x + @images[Img::MUTE].width,
             @images[Img::MUTE].y + @images[Img::MUTE].height,
           )
          if @volume > 0
            @volume = 0
            @song.volume = @volume
            @sound = false
          else
            @volume = 0.3
            @song.volume = @volume
            @sound = true
          end
        end
        # Pause area
        if area_clicked?(
             @images[Img::PAUSE].x - @images[Img::PAUSE].width,
             @images[Img::PAUSE].y - @images[Img::PAUSE].height,
             @images[Img::PAUSE].x + @images[Img::PAUSE].width,
             @images[Img::PAUSE].y + @images[Img::PAUSE].height,
           )
          if @play
            @play = false
            @song.pause
          else
            @play = true
            @song.play
          end
        end
        # Prev area
        if area_clicked?(
             @images[Img::PREV].x - @images[Img::PREV].width,
             @images[Img::PREV].y - @images[Img::PREV].height,
             @images[Img::PREV].x + @images[Img::PREV].width,
             @images[Img::PREV].y + @images[Img::PREV].height,
           )
          @song_id -= 1

          if @play
            playTrack(@song_id)
            @play = true
          else
            playTrack(@song_id)
            @song.pause
            @play = false
          end
        end
        # Fwd area
        if area_clicked?(
             @images[Img::FWD].x - @images[Img::FWD].width,
             @images[Img::FWD].y - @images[Img::FWD].height,
             @images[Img::FWD].x + @images[Img::FWD].width,
             @images[Img::FWD].y + @images[Img::FWD].height,
           )
          @song_id += 1

          if @play
            playTrack(@song_id)
            @play = true
          else
            playTrack(@song_id)
            @song.pause
            @play = false
          end
        end
      elsif @page == 3 # Page 3 - MsLeft
        # Add selected tracks to array, removing all duplicates
        # i = area_hovered(110, :playlist)
        if i = area_hovered(110, :playlist)
          @array << i
          @tracks_clicked = @array.uniq
        end

        # Add Playlist(Button)
        if area_clicked?(
             @images[Img::PLIST].x - @images[Img::PLIST].width,
             @images[Img::PLIST].y - @images[Img::PLIST].height,
             @images[Img::PLIST].x + @images[Img::PLIST].width,
             @images[Img::PLIST].y + @images[Img::PLIST].height,
           )
          # Album count + 1
          File.write("albums.txt", @albums.count + 1, mode: "r+")

          # Loop: Appending single_selected_tracks[i] // Track[selected].name, Track[selected].location
          # into array_tracks, and then assigning it to playlist.tracks
          tracks = Array.new
          for i in @tracks_clicked
            tracks << @full_tracks[i]
          end

          # Count n number of Playlist
          n = 1
          @albums.each { |album| n += 1 if album.artist.chomp == "Author" }

          # Create array of Playlists
          @playlist =
            Playlist.new(
              "images/Playlist_Albums.png",
              "Author",
              "Playlist #{n}",
              "xxxx",
              "nil",
              tracks,
            )

          @playlists << @playlist

          # Appending new/created Playlist into albums.txt
          music_file = File.new(@file_name, "a")
          music_file.write("\n" + @playlist.artwork)
          music_file.write("\n" + @playlist.artist)
          music_file.write("\n" + @playlist.title)
          music_file.write("\n" + @playlist.release_date)
          music_file.write("\n" + @playlist.genre)
          music_file.write("\n" + @tracks_clicked.count.to_s)
          @tracks_clicked.count.times do |i|
            music_file.write("\n" + @playlist.tracks[i].name.chomp)
            music_file.write("\n" + @playlist.tracks[i].location.chomp)
          end
          music_file.close

          # Reloads the file and page
          music_file = File.new(@file_name, "r")
          @albums = read_albums(music_file)
          @tracks_clicked = Array.new
          @array = Array.new

          @page = 1
        end
      else
        self.text_input = nil
      end
    end

    close if id == Gosu::KbEscape # Terminates the program
  end
end

MusicPlayerMain.new.show if __FILE__ == $0
