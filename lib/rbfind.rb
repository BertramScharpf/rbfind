#
#  rbfind.rb  --  Find replacement with many features
#
# * See the README file for the documentation of the command line tool.
# * See the RbFind for the class reference.
#

# Author: Bertram Scharpf <software@bertram-scharpf.de>
# License: BSD

=begin rdoc

= Usage

  RbFind.open                do |f| puts f.path end
  RbFind.open "dir"          do |f| puts f.path end
  RbFind.open "dir1", "dir2" do |f| puts f.path end
  RbFind.open %w(dir1 dir2)  do |f| puts f.path end
  RbFind.open "dir", :max_depth => 3 do |f| puts f.path end

  # more terse
  RbFind.run       do puts path end
  RbFind.run "dir" do puts path end


= File properties

  f.name          # file name (*)
  f.path          # file path relative to working directory (*)
  f.fullpath      # full file path (*)
  f.dirname       # dirname of path
  f.ext           # file name extension
  f.without_ext   # file name without extension
  f.depth         # step depth
  f.hidden?       # filename starting with "." (No Windows version, yet.)
  f.visible?      # not hidden?
  f.stat          # file status information (File::Stat object)
  f.mode          # access mode (like 0755, 0644)
  f.age           # age in seconds since walk started
  f.age_s         #   dto. (alias)
  f.age_secs      #   dto. (alias)
  f.age_m         # age in minutes
  f.age_mins      #   dto. (alias)
  f.age_h         # age in hours
  f.age_hours     #   dto. (alias)
  f.age_d         # age in days
  f.age_days      #   dto. (alias)
  f.user          # owner
  f.owner         #   dto. (alias)
  f.group         # group owner
  f.readlink      # symlink pointer or nil (*)
  f.broken_link?  # what you expect
  f.arrow         # ls-style "-> symlink" suffix (*)

                  # (*) = colored version available (see below)

  f.open  { |o| ... }    # open file
  f.read n = nil         # read first n bytes, nil reads to eof
  f.lines { |l,i| ... }  # open file and yield each |line,lineno|
  f.grep re              # lines with `l =~ re and colsep path, i, l'
  f.binary? n = 1   # test whether first n blocks contain null characters
  f.bin?            # alias for binary?

  f.vimswap?      # it is a Vim swapfile

Further will be redirected to the stat object (selective):

    f.directory?
    f.executable?
    f.file?
    f.pipe?
    f.socket?
    f.symlink?

    f.readable?
    f.writable?
    f.size
    f.zero?

    f.uid
    f.gid
    f.owned?
    f.grpowned?

    f.dir?         # alias for f.directory?

Derivated from stat:

    f.stype        # one-letter (short) version of ftype
    f.modes        # rwxr-xr-x style modes

    f.filesize                    # returns size for files, else nil
    f.filesize { |s| s > 1024 }   # returns block result for files


= Actions

    f.prune   # do not descend directory; abort current entry
    f.novcs   # omit .svn, CVS and .git directories

    f.colsep path, ...   # output parameters in a line separated by colons
    f.col_sep            #   dto. (alias)
    f.tabsep path, ...   # separate by tabs
    f.tab_sep            #
    f.spcsep path, ...   # separate by spaces
    f.spc_sep            #
    f.spacesep path, ... #
    f.space_sep          #
    f.csv sep, path, ... # separate by user-defined separator

    f.rename newname   # rename, but leave it in the same directory


= Color support

    f.cname       # colorized name
    f.cpath       # colorized path
    f.cfullpath   # colorized fullpath
    f.creadlink   # colored symlink pointer
    f.carrow      # colored "-> symlink" suffix

    f.color arg   # colorize argument
    f.colour arg  # alias

    RbFind.colors str      # define colors
    RbFind.colours str     # alias

    Default color setup is "xxHbexfxcxdxbxegedabagacadAx".
    In case you did not call RbFind.colors, the environment variables
    RBFIND_COLORS and RBFIND_COLOURS are looked up. If neither is given
    but LSCOLORS is set, the fields 2-13 default to that.

    The letters mean:
      a = black, b = red, c = green, d = brown, e = blue,
      f = magenta, g = cyan, h = light grey
      upper case = bold (resp. dark grey, yellow)

      first character = foreground, second character = background

    The character pairs map the following types:
       0  regular file
       1  nonexistent (broken link)
       2  directory
       3  symbolic link
       4  socket
       5  pipe
       6  executable
       7  block special
       8  character special
       9  executable with setuid bit set
      10  executable with setgid bit set
      11  directory writable to others, with sticky bit
      12  directory writable to others, without sticky bit
      13  whiteout
      14  unknown

    f.suffix      # ls-like suffixes |@=/%* for pipe, ..., executable


= Examples

Find them all:

    RbFind.open do |f| puts f.path end

Omit version control:

    RbFind.open "myproject" do |f|
      f.prune if f.name == ".svn"
      puts f.path
    end

    # or even
    RbFind.open "myproject" do |f|
      f.novcs
      puts f.path
    end

Mention directory contents before directory itself:

    RbFind.open "myproject", :depth => true do |f|
      puts f.path
    end

Limit search depth:

    RbFind.open :max_depth => 2 do |f|
      puts f.path
    end

Unsorted (alphabetical sort is default):

    RbFind.open :sort => false do |f|
      puts f.path
    end

Reverse sort:

    RbFind.open :sort => -1 do |f|
      puts f.path
    end

Sort without case sensitivity and preceding dot:

    s = proc { |x| x =~ /^\.?/ ; $'.downcase }
    RbFind.open :sort => s do |f|
      puts f.path
    end

=end

class RbFind

  VERSION = "1.3"

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
      @max_depth = md.to_i if md
      st = params.delete :sort
      @sort = sort_parser st
      @dir_error = params.delete :dir_error
      @file_error = params.delete :file_error
      params.empty?  or
        raise RuntimeError, "Unknown parameter(s): #{params.keys.join ','}."
    end
    @do_level = method dl||:do_level

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

  # :call-seq:
  #    broken_link?()   -> true or false
  #
  def broken_link?
    not (File.stat @path rescue nil) if stat.symlink?
  end

  ARROW = " -> "  # :nodoc:

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

  # :stopdoc:
  MINUTE = 60
  HOUR   = 60*MINUTE
  DAY    = 24*HOUR
  # :startdoc:

  def age_mins  ; age / MINUTE ; end
  alias age_m    age_mins
  def age_hours ; age / HOUR   ; end
  alias age_h    age_hours
  def age_days  ; age / DAY    ; end
  alias age_d    age_days

  private

  def method_missing sym, *args, &block
    stat.send sym, *args, &block
  rescue NoMethodError
    raise NoMethodError, "Undefined method `#{sym}'."
  end

  public

  def dir? ; stat.directory? ; end

  # :call-seq:
  #    stype()   -> str
  #
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

  # :call-seq:
  #    modes()   -> str
  #
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

  # :call-seq:
  #    filesize => nil or int
  #    filesize { |size| ... } => obj
  #
  # Returns the files size. When the object is not a regular file,
  # nil will be returned or the block will not be called.
  #
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

    def colors str
      @cols = []
      str.scan /(.)(.)/i do
        fg, bg = $~.captures.map { |x| x.downcase[0] - ?a }
        a = []
        case fg
          when 0..7 then a.push 30 + fg
        end
        a.push 1 if $1 == $1.upcase
        case bg
          when 0..7 then a.push 40 + bg
        end
        e = a.join ";"
        @cols.push e
      end
    end
    alias colours colors

    def colored arg, num
      @cols or colors col_str
      "\e[#{@cols[num]}m#{arg}\e[m"
    end
    alias coloured colored

    private

    def col_str
      ENV[ "RBFIND_COLORS"] || ENV[ "RBFIND_COLOURS"] || (
        env = DEFAULT_COLORS.dup
        els = ENV[ "LSCOLORS"]
        if els then
          env[ 2*2, els.length] = els
        end
        env
      )
    end

  end


  # :call-seq:
  #    suffix()   -> str
  #
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


  # :call-seq:
  #    user()   -> str
  #
  # Return user name or uid as string if unavailable.
  #
  def user
    u = stat.uid
    (etc.getpwuid u).name rescue u.to_s
  end
  alias owner user

  # :call-seq:
  #    group()   -> str
  #
  # Return group name or gid as string if unavailable.
  #
  def group
    g = stat.gid
    (etc.getgrgid g).name rescue g.to_s
  end


  # :call-seq:
  #    open() { |h| ... }    -> obj
  #
  # Open the file for reading. When the object is not a regular file,
  # nothing will be done.
  #
  def open &block
    File.open path, &block if file?
  rescue Errno::EACCES
    @file_error or raise
    @file_error.call $!
  end

  # :call-seq:
  #    read( n = nil)    -> str or nil
  #
  # Read the first <code>n</code> bytes or return <code>nil</code>
  # for others that regular files. <code>nil</code> reads to end of file.
  #
  def read n = nil
    open { |o| o.read n }
  end

  # :call-seq:
  #    lines { |l,i| ... }    -> nil
  #
  # Yield line by line together with the line number <code>i</code>.
  #
  def lines
    block_given? or return lines do end
    open { |file|
      n = 0
      file.each_line { |line|
        n += 1
        line.chomp!
        yield line, n
      }
      n
    }
  end

  def grep re
    lines { |l,i| l =~ re and colsep path, i, l }
  end

  BLOCK_SIZE = 512   # :nodoc:

  # :call-seq:
  #    binary?( n = 1)   -> true or false
  #
  # Test whether the first <code>n</code> blocks contain null characters.
  #
  def binary? n = 1
    open { |file|
      loop do
        if n then
          break if n <= 0
          n -= 1
        end
        b = file.read BLOCK_SIZE
        b or break
        return true if b[ "\0"]
      end
    }
    false
  end
  alias bin? binary?


  # :stopdoc:
  class Prune < Exception ; end
  # :startdoc:

  # :call-seq:
  #    prune()   -> (does not return)
  #
  # Abandon the current object (directory) and ignore all subdirectories.
  #
  def prune ; raise Prune ; end

  # :call-seq:
  #    novcs()   -> nil
  #
  # Perform <code>prune</code> if the current object is a CVS, Subversion or
  # Git directory.
  #
  def novcs
    prune if %w(CVS .svn .git).include? name
  end
  alias no_vcs novcs

  # :call-seq:
  #    vimswap?   -> true or false
  #
  # Check whether the current object is a Vim swapfile.
  #
  def vimswap?
    if name =~ /\A(\..+)?\.sw[a-z]\z/i then
      mark = read 5
      mark == "b0VIM"
    end
  end

  # Windows has ":" in filenames ("C:\...")
  COLON = File::ALT_SEPARATOR ? "|" : ":"   # :nodoc:

  def colsep *args
    csv COLON, *args
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
      when Proc    then st
      when Numeric then st
      when true    then +1
      when false   then  0
      when nil     then +1
      else
        case st.to_s
          when "^", "reverse", /^desc/, /^-/ then -1
          when "unsorted", "*"               then  0
          else                                    +1
        end
    end
  end

  # :stopdoc:
  RE_ABSOLUTE = File::ALT_SEPARATOR ?
    /\A([A-Z]:)?
      [#{Regexp.quote File::SEPARATOR}#{Regexp.quote File::ALT_SEPARATOR}]/ix :
    /\A#{Regexp.quote File::SEPARATOR}/
  # :startdoc:

  def build_path
    @path = File.join @levels
    # File.expand_path will expand ~ which is not desired here.
    @fullpath = if @path =~ RE_ABSOLUTE then
      @path
    else
      File.join @wd, @path
    end
  end

  def walk
    return if @max_depth and depth > @max_depth
    build_path
    @count += 1
    @do_level.call
    @dirname = nil
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
    if @sort.respond_to? :call then
      dir = dir.sort_by &@sort
    elsif @sort and @sort.nonzero? then
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
    self.class.colored arg, code
  end

  def col_type
    # Overwrite this to define custom colors
    # Example:
    #   case ext
    #     when ".png", /\.jpe?g$/, /\.tiff?$/ then 15
    #     when /\.tar\.(gz|bz2)$/             then 16
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

