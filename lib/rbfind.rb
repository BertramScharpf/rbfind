#
#  rbfind.rb  --  Find replacement with many features
#
# * See the README file for the documentation of the command line tool.
# * See the RbFind for the class reference.
#

# Author: Bertram Scharpf <software@bertram-scharpf.de>
# License: BSD

# Description:
#
#   Usage:
#     RbFind.open                do |f| puts f.path end
#     RbFind.open "dir"          do |f| puts f.path end
#     RbFind.open "dir1", "dir2" do |f| puts f.path end
#     RbFind.open %w(dir1 dir2)  do |f| puts f.path end
#     RbFind.open "dir", :max_depth => 3 do |f| puts f.path end
#
#     # more terse
#     RbFind.run       do puts path end
#     RbFind.run "dir" do puts path end
#
#
#   File properties:
#     f.name          # file name (*)
#     f.path          # file path relative to working directory (*)
#     f.fullpath      # full file path (*)
#     f.dirname       # dirname of path
#     f.ext           # file name extension
#     f.without_ext   # file name without extension
#     f.depth         # step depth
#     f.hidden?       # filename starting with "." (No Windows version, yet.)
#     f.visible?      # not hidden?
#     f.stat          # file status information (File::Stat object)
#     f.mode          # access mode (like 0755, 0644)
#     f.age           # age in seconds since walk started
#     f.age_s         #   dto. (alias)
#     f.age_secs      #   dto. (alias)
#     f.age_m         # age in minutes
#     f.age_mins      #   dto. (alias)
#     f.age_h         # age in hours
#     f.age_hours     #   dto. (alias)
#     f.age_d         # age in days
#     f.age_days      #   dto. (alias)
#     f.user          # owner
#     f.owner         #   dto. (alias)
#     f.group         # group owner
#     f.readlink      # symlink pointer or nil (*)
#     f.broken_link?  # what you expect
#     f.arrow         # ls-style "-> symlink" suffix (*)
#
#                     # (*) = colored version available (see below)
#
#     f.open  { |o| ... }    # open file
#     f.read n               # read first n bytes
#     f.lines { |l,i| ... }  # open file and yield each |line,lineno|
#     f.grep re              # lines with `l =~ re and colsep path, i, l'
#     f.binary? n = 1   # test whether first n blocks contain null characters
#     f.bin?            # alias for binary?
#
#     f.vimswap?      # it is a Vim swapfile
#
#   Further will be redirected to the stat object (selective):
#     f.directory?
#     f.executable?
#     f.file?
#     f.pipe?
#     f.socket?
#     f.symlink?
#
#     f.readable?
#     f.writable?
#     f.size
#     f.zero?
#
#     f.uid
#     f.gid
#     f.owned?
#     f.grpowned?
#
#     f.dir?         # alias for f.directory?
#
#   Derivated from stat:
#     f.stype        # one-letter (short) version of ftype
#     f.modes        # rwxr-xr-x style modes
#
#     f.filesize                    # returns size for files, else nil
#     f.filesize { |s| s > 1024 }   # returns block result for files
#
#   Actions:
#     f.prune   # do not descend directory; abort current entry
#     f.novcs   # omit .svn, CVS and .git directories
#
#     f.colsep path, ...   # output parameters in a line separated by colons
#     f.col_sep            #   dto. (alias)
#     f.tabsep path, ...   # separate by tabs
#     f.tab_sep            #
#     f.spcsep path, ...   # separate by spaces
#     f.spc_sep            #
#     f.spacesep path, ... #
#     f.space_sep          #
#     f.csv sep, path, ... # separate by user-defined separator
#
#     f.rename newname   # rename, but leave it in the same directory
#
#   Color support:
#     f.cname       # colorized name
#     f.cpath       # colorized path
#     f.cfullpath   # colorized fullpath
#     f.creadlink   # colored symlink pointer
#     f.carrow      # colored "-> symlink" suffix
#
#     f.color arg   # colorize argument
#     f.colour arg  # alias
#
#     RbFind.colors str      # define colors
#     RbFind.colours str     # alias
#
#     Default color setup is "xxHbexfxcxdxbxegedabagacadAx".
#     In case you did not call RbFind.colors, the environment variables
#     RBFIND_COLORS and RBFIND_COLOURS are looked up. If neither ist given
#     but LSCOLORS is set, the fields 2-13 default to that.
#
#     The letters mean:
#       a = black, b = red, c = green, d = brown, e = blue,
#       f = magenta, g = cyan, h = light grey
#       upper case = bold (resp. dark grey, yellow)
#
#       first character = foreground, second character = background
#
#     The character pairs map the following types:
#        0  regular file
#        1  nonexistent (broken link)
#        2  directory
#        3  symbolic link
#        4  socket
#        5  pipe
#        6  executable
#        7  block special
#        8  character special
#        9  executable with setuid bit set
#       10  executable with setgid bit set
#       11  directory writable to others, with sticky bit
#       12  directory writable to others, without sticky bit
#       13  whiteout
#       14  unknown
#
#     f.suffix      # ls-like suffixes |@=/%* for pipe, ..., executable
#
# Examples:
#
#   Find them all:
#     RbFind.open do |f| puts f.path end
#
#   Omit version control:
#     RbFind.open "myproject" do |f|
#       f.prune if f.name == ".svn"
#       puts f.path
#     end
#     # or even
#     RbFind.open "myproject" do |f|
#       f.nosvn
#       puts f.path
#     end
#
#   Mention directory contents before directory itself:
#     RbFind.open "myproject", :depth => true do |f|
#       puts f.path
#     end
#
#   Limit search depth:
#     RbFind.open :max_depth => 2 do |f|
#       puts f.path
#     end
#
#   Unsorted (alphabetical sort is default):
#     RbFind.open :sort => false do |f|
#       puts f.path
#     end
#
#   Reverse sort:
#     RbFind.open :sort => -1 do |f|
#       puts f.path
#     end
#
#   Sort without case sensitivity and preceding dot:
#     s = proc { |x| x =~ /^\.?/ ; $'.downcase }
#     RbFind.open :sort => s do |f|
#       puts f.path
#     end
#

class RbFind

  SPECIAL_DIRS = %w(. ..)
  CUR_DIR, SUPER_DIR = *SPECIAL_DIRS

  class <<self
    private :new
    def open *args, &block
      params = case args.last
        when Hash then args.pop
      end
      args.flatten!
      if args.any? then
        args.inject 0 do |count,path|
          f = new path, params, &block
          count + f.count
        end
      else
        f = new nil, params, &block
        f.count
      end
    end
    def run *args, &block
      open *args do |f| f.instance_eval &block end
    end
  end

  attr_reader :count, :wd, :start

  def initialize path, params = nil, &block
    @levels = []
    @block = block

    if params then
      params = params.dup
      dl = :do_level_depth if params.delete :depth
      md = params.delete :max_depth
      st = params.delete :sort
      de = params.delete :dir_error
      fe = params.delete :file_error
      params.empty?  or
        raise RuntimeError, "Unknown parameter(s): #{params.keys.join ','}."
    end
    @do_level  = method dl||:do_level
    @max_depth = md.to_i if md
    sort_parser st
    @dir_error = de
    @file_error = fe

    @wd, @start = Dir.getwd, Time.now
    @count = 0
    if path then
      raise Errno::ENOENT, path unless File.exists? path
      @levels.push path
      walk
    else
      build_path
      scan_dir
    end
  end

  def name     ; @levels.last ; end
  def path     ; @path        ; end
  def fullpath ; @fullpath    ; end

  def dirname
    @dirname ||= File.dirname @path
  end

  def ext         ; File.extname name ; end
  def without_ext ; name[ /^(.+?)(?:\.[^.]+)?$/, 1 ].to_s ; end

  def depth ; @levels.size ; end

  def hidden?  ; name =~ /^\./  ; end
  def visible? ; not hidden?    ; end

  def stat ; File.lstat @path ; end
  def mode ; stat.mode        ; end

  def readlink
    File.readlink @path if stat.symlink?
  end

  def creadlink
    if stat.symlink? then
      s = File.stat @path rescue nil
      l = File.readlink @path
      (col_stat l, s)
    end
  end

  def broken_link?
    not (File.stat @path rescue nil) if stat.symlink?
  end

  ARROW = " -> "

  def arrow
    ARROW + (File.readlink @path) if stat.symlink?
  end

  def carrow
    r = creadlink
    ARROW + r if r
  end

  def age ; @start - stat.mtime ; end
  alias age_secs age
  alias age_s    age_secs

  MINUTE = 60
  def age_mins  ; age / MINUTE ; end
  alias age_m    age_mins

  HOUR   = 60*MINUTE
  def age_hours ; age / HOUR   ; end
  alias age_h    age_hours

  DAY    = 24*HOUR
  def age_days  ; age / DAY    ; end
  alias age_d    age_days

  def method_missing sym, *args, &block
    stat.send sym, *args, &block
  rescue NoMethodError
    raise NoMethodError, "Undefined method `#{sym}'."
  end

  def dir? ; stat.directory? ; end

  def stype
    m = stat.mode >> 12 rescue nil
    case m
      when 001 then "p"
      when 002 then "c"
      when 004 then "d"
      when 006 then "b"
      when 010 then "-"
      when 012 then "l"
      when 014 then "s"
      when 016 then "w"
      when nil then "#"
      else          "?"
    end
  end

  def modes
    m = stat.mode
    r = ""
    3.times {
      h = m & 07
      m >>= 3
      r.insert 0, ((h & 01).nonzero? ? "x" : "-")
      r.insert 0, ((h & 02).nonzero? ? "w" : "-")
      r.insert 0, ((h & 04).nonzero? ? "r" : "-")
    }
    if (m & 04).nonzero? then
      r[ 2] = r[ 2, 1] == "x" ? "s" : "S"
    end
    if (m & 02).nonzero? then
      r[ 5] = r[ 5, 1] == "x" ? "s" : "S"
    end
    if (m & 01).nonzero? then
      r[ 8] = r[ 8, 1] == "x" ? "t" : "T"
    end
    r
  end

  def filesize
    if block_given? then
      yield stat.size if file?
    else
      stat.size if file?
    end
  end


  def cname     ; color name     ; end
  def cpath     ; color path     ; end
  def cfullpath ; color fullpath ; end

  def color arg
    col_stat arg, stat
  end
  alias colour color

  DEFAULT_COLORS = "xxHbexfxcxdxbxegedabagacadAx"

  class <<self

    def colors str = nil
      str ||= DEFAULT_COLORS
      pairs = str.scan /../
      @@cols = col_letters pairs
    end
    alias colours colors

    def col_letters pairs
      pairs.map do |fgbg|
        fg, bg = fgbg.split ""
        fg = case fg
          when "a".."h" then "#{30 + fg[0] - ?a}"
          when "A".."H" then "#{30 + fg[0] - ?A};1"
        end
        bg = case bg
          when "a".."h" then "#{40 + bg[0] - ?a}"
          when "A".."H" then "#{40 + bg[0] - ?A}"
        end
        [fg, bg].compact.join ";"
      end
    end

  end


  def suffix
    m = stat.mode >> 12 rescue nil
    case m
      when 001 then "|"
      when 002 then " "
      when 004 then "/"
      when 006 then " "
      when 010 then stat.executable? ? "*" : " "
      when 012 then "@"
      when 014 then "="
      when 016 then "%"
      else          "?"
    end
  end


  def user
    u = stat.uid
    (etc.getpwuid u).name rescue u.to_s
  end
  alias owner user

  def group
    g = stat.gid
    (etc.getgrgid g).name rescue g.to_s
  end


  def open &block
    file? and File.open path, &block
  rescue Errno::EACCES
    @file_error or raise
    @file_error.call $!
  end

  def read n
    open { |o| o.read n }.to_s
  end

  def lines
    n = 0
    open { |file| file.each { |line| n += 1 ; line.chomp! ; yield line, n } }
    nil
  end

  def grep re
    lines { |l,i| l =~ re and colsep path, i, l }
  end

  def binary? n = 1
    open { |file|
      loop do
        if n then
          break if n <= 0
          n -= 1
        end
        b = file.read 512
        b or break
        return true if b[ "\0"]
      end
    }
    false
  end
  alias bin? binary?


  class Prune < Exception ; end
  def prune ; raise Prune ; end

  def novcs
    prune if %w(CVS .svn .git).include? name
  end
  alias no_vcs novcs

  def vimswap?
    if name =~ /\.sw[a-z]\z/i then
      mark = read 5
      mark == "b0VIM"
    end
  end

  def colsep *args
    csv ":", *args
  end
  alias col_sep colsep

  def tabsep *args
    csv "\t", *args
  end
  alias tab_sep tabsep

  def spcsep *args
    csv " ", *args
  end
  alias spc_sep spcsep
  alias space_sep spc_sep
  alias spacesep spcsep

  def csv sep, *args
    e = args.join sep
    puts e
  end


  def rename newname
    fp = @fullpath
    nb = File.basename newname
    newname == nb or raise RuntimeError,
          "#{self.class}: rename to `#{newname}' may not be a path."
    @levels.pop
    @levels.push newname
    build_path
    File.rename fp, @fullpath
  end

  private

  def sort_parser st
    case st
      when Proc    then @sort_proc = st
      when Numeric then @sort = st
      when true    then @sort = +1
      when false   then @sort =  0
      when nil     then @sort = +1
      else
        @sort = case st.to_s
          when "^", "reverse", /^desc/, /^-/ then -1
          when "unsorted", "*"               then  0
          else                                    +1
        end
    end
  end

  def build_path
    @path = File.join @levels
    @fullpath = File.expand_path @path, @wd
    @dirname = nil
  end

  def walk
    return if @max_depth and depth > @max_depth
    build_path
    @count += 1
    @do_level.call
  end

  def do_level
    begin
      @block.call self
    rescue Prune
      return
    end
    scan if File.exists? @path
  end

  def do_level_depth
    path, fullpath = @path, @fullpath
    scan
    @path, @fullpath = path, fullpath
    begin
      @block.call self
    rescue Prune
      raise RuntimeError, "#{self.class}: prune doesn't work with :depth."
    end
  end

  def scan
    scan_dir if stat.directory?
  end

  def read_dir
    (Dir.entries @fullpath) - SPECIAL_DIRS
  rescue Errno::EACCES
    @dir_error or raise
    @dir_error.call $!
    []
  end

  def scan_dir
    dir = read_dir
    if @sort_proc then
      dir = dir.sort_by &@sort_proc
    elsif @sort.nonzero? then
      dir.sort!
      dir.reverse! if @sort < 0
    end
    dir.each { |f|
      @levels.push f
      walk
      @levels.pop
    }
  end

  def col_stat arg, s
    m = s.mode if s
    code = case m && m >> 12
      when 001 then                        5
      when 002 then                        8
      when 004 then
        if (m & 0002).nonzero? then
          if (m & 01000).nonzero? then    11
          else                            12
          end
        else                               2
        end
      when 006 then                        7
      when 010 then
        col_type or \
        if (m & 0111).nonzero? then
          if (m & 04000).nonzero? then     9
          elsif (m & 02000).nonzero? then 10
          else                             6
          end
        else                               0
        end
      when 012 then                        3
      when 014 then                        4
      when 016 then                       13
      when nil then                        1
      else                                14
    end
    unless defined? @@cols then
      env = ENV[ "RBFIND_COLORS"].to_s||ENV[ "RBFIND_COLOURS"].to_s
      if env.empty? then
        els = ENV[ "LSCOLORS"].to_s
        if els.any? then
          env = DEFAULT_COLORS.dup
          env[ 2*2, els.length] = els
        end
      end
      env = nil if env.empty?
      self.class.colors env
    end
    "\e[#{@@cols[code]}m#{arg}\e[m"
  end

  def col_type
    # Overwrite this to define custom colors
    # Example:
    #   c = RbFind.col_letters "ax"
    #   case name
    #     when /\.mpg$/ then c[ 0]
    #   end
  end

  def etc
    Etc
  rescue NameError
    require "etc" and retry
  end

  class <<self
    def find *args
      raise NotImplementedError, "This is not the standard Find."
    end
  end

end

