#
#  rbfind.rb  --  Find replacement with many features
#

class Dir

  SPECIAL_DIRS = %w(. ..)
  CUR_DIR, SUPER_DIR = *SPECIAL_DIRS

  method_defined? :each_child or def each_child
    s = SPECIAL_DIRS.dup
    each { |f|
      next if s.delete f
      yield f
    }
  end

  method_defined? :children or def children
    entries - SPECIAL_DIRS
  end

end

class File

  class Stat

    def identical? oth
      oth = self.class.new oth unless self.class === oth
      dev == oth.dev and ino == oth.ino
    end

    def stype
      case mode >> 12
        when 001 then "p"
        when 002 then "c"
        when 004 then "d"
        when 006 then "b"
        when 010 then "-"
        when 012 then "l"
        when 014 then "s"
        when 016 then "w"
        else          "?"
      end
    end

    def suffix
      case mode >> 12
        when 001 then "|"
        when 002 then " "
        when 004 then "/"
        when 006 then " "
        when 010 then executable? ? "*" : " "
        when 012 then "@"
        when 014 then "="
        when 016 then "%"
        else          "?"
      end
    end

    def modes
      r = ""
      m = mode
      3.times {
        r.insert 0, ((m & 01).nonzero? ? "x" : "-")
        r.insert 0, ((m & 02).nonzero? ? "w" : "-")
        r.insert 0, ((m & 04).nonzero? ? "r" : "-")
        m >>= 3
      }
      (m & 04).nonzero? and r[ 2] = r[ 2] == "x" ? "s" : "S"
      (m & 02).nonzero? and r[ 5] = r[ 5] == "x" ? "s" : "S"
      (m & 01).nonzero? and r[ 8] = r[ 8] == "x" ? "t" : "T"
      r
    end

  end

end


=begin rdoc

== Usage

See the README file or "rbfind -h" for a documentation of the command line
tool.

In Ruby programs, you may call:

  RbFind.open                do |f| puts f.path end
  RbFind.open "dir"          do |f| puts f.path end
  RbFind.open "dir1", "dir2" do |f| puts f.path end
  RbFind.open %w(dir1 dir2)  do |f| puts f.path end
  RbFind.open "dir", :max_depth => 3 do |f| puts f.path end

  # more terse
  RbFind.run       do puts path end
  RbFind.run "dir" do puts path end


== File properties

  f.name          # file name (*)
  f.path          # file path relative to working directory (*)
  f.fullpath      # full file path (*)
  f.path!         # directories with a slash appended (*)
  f.fullpath!     # directories with a slash appended (*)
  f.dirname       # dirname of path
  f.ext           # file name extension
  f.without_ext   # file name without extension
  f.depth         # step depth
  f.hidden?       # filename starting with "." (No Windows version, yet.)
  f.visible?      # not hidden?
  f.stat          # file status information (File::Stat object)
  f.mode          # access mode (like 0755, 0644)
  f.age           # age in seconds since walk started
  f.user          # owner
  f.owner         #   dto. (alias)
  f.group         # group owner
  f.readlink      # symlink pointer or nil (*)
  f.broken_link?  # what you expect
  f.arrow         # ls-style "-> symlink" suffix (*)

                  # (*) = colored version available (see below)

  f.empty?               # directory is empty
  f.entries              # directory entries

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


== Actions

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


== Color support

    f.cname       # colorized name
    f.cpath       # colorized path
    f.cpath!      # colorized path!
    f.cfullpath   # colorized fullpath
    f.cfullpath!  # colorized fullpath!
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
    A Gnu LS_COLOR-style string may also be given, though glob patterns will
    not be unregarded. If LS_COLORS is set, the colors default to that.

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


== Encoding issues

Ruby raises an ArgumentError if, for example, an ISO8859-1-encoded
string gets read in as UTF-8-encoded and then is matched against a
UTF-8-encoded regular expression. This will happen if you are
running RbFind from an environment with something like
LANG="de_DE.UTF-8" and if you are searching directories containing
single-byte encoded file names or files with single-byte or binary
content.

The #grep facility will condone encoding mismatches by calling
the String#scrub! method. But neither the #lines and #read function
will do any transformation nor will the file names and the path
specifications be changed.

In short, if you are using the #grep method, or the -g option on the
command line you will not need to care about encoding problems. On
the other hand, if you specify the =~ operator, you will be
responsible for calling the String#scrub method yourself. Please do
not try to call the String#scrub! (bang) method for the name and path
variables because these will be used in the further processing.


== Examples

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

  VERSION = "1.14".freeze

  class <<self
    private :new
    def open *args, &block
      params = case args.last
        when Hash then args.pop
      end
      args.flatten!
      if args.any? then
        count = 0
        args.each do |path|
          f = new path, count, params, &block
          count = f.count
        end
        count
      else
        f = new nil, 0, params, &block
        f.count
      end
    end
    def run *args, &block
      open *args do |f| f.instance_eval &block end
    end
  end

  attr_reader :count, :wd, :start

  def initialize path, count, params = nil, &block
    @levels = []
    @block = block

    if params then
      params = params.dup
      dl = :do_level_depth if params.delete :depth
      md = params.delete :max_depth ; @max_depth = md.to_i if md
      st = params.delete :sort ; @sort = sort_parser st
      @follow = params.delete :follow
      @error = params.delete :error
      params.empty?  or
        raise RuntimeError, "Unknown parameter(s): #{params.keys.join ','}."
    end
    @do_level = method dl||:do_level

    @ostat = $stdout.stat
    @ostat = nil unless @ostat.file?

    @start, @count = Time.now, count
    @wd = Dir.getwd
    if path then
      @max_depth += 1 if @max_depth
      File.lstat path
      @wd = nil unless absolute_path? path
      @levels.push path
      walk
    else
      build_path
      scan_dir
    end
  end

  private

  def append_slash s ; (File.directory? s) ? (File.join s, "") : s ; end

  public

  def name      ; @levels.last ; end
  def path      ; @path        ; end
  def fullpath  ; @fullpath    ; end
  def path!     ; append_slash @path     ; end
  def fullpath! ; append_slash @fullpath ; end

  def dirname
    d = File.dirname @fullpath
    File.basename d
  end

  def ext         ; File.extname name ; end
  def without_ext ; name[ /^(.+?)(?:\.[^.]+)?$/, 1 ].to_s ; end

  def depth ; @levels.size ; end

  def hidden?  ; name =~ /^\./ ; end
  def visible? ; not hidden?   ; end

  def stat ; @stat ||= File.lstat @path ; end
  def mode ; stat.mode                  ; end

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
    return unless stat.symlink?
    !File.stat @path rescue true
  end

  ARROW = " -> "  # :nodoc:

  def arrow
    ARROW + (File.readlink @path) if stat.symlink?
  end

  def carrow
    r = creadlink
    ARROW + r if r
  end

  def now ; @start ; end
  def age ; @start - stat.mtime ; end

  private

  def method_missing sym, *args, &block
    stat.send sym, *args, &block
  rescue NoMethodError
    super
  end

  public

  def dir? ; stat.directory? ; end

  # :call-seq:
  #    filesize => nil or int
  #    filesize { |size| ... } => obj
  #
  # Returns the files size. When the object is not a regular file,
  # nil will be returned or the block will not be called.
  #
  def filesize
    if block_given? then
      yield filesize
    else
      stat.size if file?
    end
  end


  def cname      ; color name      ; end
  def cpath      ; color path      ; end
  def cfullpath  ; color fullpath  ; end
  def cpath!     ; color path!     ; end
  def cfullpath! ; color fullpath! ; end

  def color arg
    col_stat arg, stat
  end
  alias colour color

  DEFAULT_COLORS = "xxHbexfxcxdxbxegedabagacadAx"

  class <<self

    def colors str
      if str =~ /:/ then
        h = {}
        (str.split ":").each { |a|
          t, c = a.split "="
          h[  t] = c
        }
        %w(rs or di ln so pi ex bd cd su sg tw ow - -).map { |t| h[ t] }
      else
        cols = []
        str.scan /(.)(.)/i do
          fg, bg = $~.captures.map { |x| x.downcase.ord - ?a.ord }
          a = []
          case fg
            when 0..7 then a.push 30 + fg
          end
          a.push 1 if $1 == $1.upcase
          case bg
            when 0..7 then a.push 40 + bg
          end
          e = a.join ";"
          cols.push e
        end
        cols
      end
    end
    alias colours colors

    def colored arg, num
      @cols ||= colors col_str
      "\e[#{@cols[num]}m#{arg}\e[m"
    end
    alias coloured colored

    private

    def col_str
      ENV[ "RBFIND_COLORS"] || ENV[ "RBFIND_COLOURS"] || ENV[ "LS_COLORS"] || (
        env = DEFAULT_COLORS.dup
        els = ENV[ "LSCOLORS"]
        if els then
          env[ 2*2, els.length] = els
        end
        env
      )
    end

  end


  def etc
    Etc
  rescue NameError
    require "etc" and retry
    raise
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
  #    empty?()     -> true or false
  #
  # Look up if the directory is empty. If the object is not a directory,
  # +nil+ is returned.
  #
  def empty?
    read_dir.each_child { |f| return false }
    true
  rescue Errno::ENOTDIR
  end

  # :call-seq:
  #    contains?( name)     -> true or false
  #
  # Check whether a directory contains an entry.
  #
  def contains? name
    c = File.join @path, name
    File.exists? c
  end

  # :call-seq:
  #    entires()     -> ary
  #
  # Return all entries in an array. If the object is not a directory,
  # +nil+ is returned.
  #
  def entries
    read_dir.children
  rescue Errno::ENOTDIR
  end
  alias children entries

  # :call-seq:
  #    open() { |h| ... }    -> obj
  #
  # Open the file for reading. If the object is not a regular file,
  # nothing will be done.
  #
  def open &block
    if @ostat and @ostat.identical? @path then
      raise "Refusing to open output file."
    end
    handle_error Errno::EACCES do
      File.open @path, &block if file?
    end
  end

  # :call-seq:
  #    read( n = nil)               -> str or nil
  #    read( n = nil) { |b| ... }   -> nil
  #
  # Read the first +n+ bytes or return +nil+ for others than regular
  # files. +nil+ reads to end of file. If a block is given, chonks of
  # +n+ bytes (or all) will be yielded.
  #
  def read n = nil
    open { |o|
      if block_given? then
        if n then
          while (r = o.read n) do
            yield r
          end
        else
          yield o.read
        end
      else
        o.read n
      end
    }
  end

  # :call-seq:
  #    lines { |l,i| ... }    -> nil
  #
  # Yield line by line together with the line number <code>i</code>.
  #
  def lines
    block_given? or return lines do end
    r = false
    open { |file|
      n = 0
      file.each_line { |l|
        l.chomp!
        n += 1
        set_predefs l, n
        r ||= true if yield l, n
      }
      r
    }
  end

  def grep re, color = nil
    case color
      when /\A\d+(?:;\d+)*\z/, nil, false then
      when true then color = "31;1"  # red
      else           raise "Illegal color spec: #{color}"
    end
    lines { |l,i|
      l.scrub!
      l =~ re or next
      if color then
        l = "#$`\e[#{color}m#$&\e[m#$'"
      end
      colsep @path, i, l
      true
    }
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
  # Git, etc. directory.
  #
  def novcs
    prune if %w(CVS .svn .git .hg .fslckout).include? name
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
  alias p spcsep

  def csv sep, *args
    e = args.join sep
    puts e
  end

  def rename newname
    p = @path
    nb = File.basename newname
    newname == nb or raise RuntimeError,
          "#{self.class}: rename to `#{newname}' may not be a path."
    nb.freeze
    @levels.pop
    @levels.push nb
    build_path
    File.rename p, @path
    nil
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

  def absolute_path? p
    loop do
      q = File.dirname p
      break if q == p
      p = q
    end
    p != Dir::CUR_DIR
  end

  def build_path
    @path = File.join @levels
    @fullpath = if @wd then
      File.join @wd, @path
    else
      @path
    end
    if @path.empty? then @path = Dir::CUR_DIR end
    @fullpath.freeze
    @path.freeze
    @stat = nil
  end

  def walk
    return if @max_depth and depth > @max_depth
    build_path
    @count += 1
    @do_level.call
  end

  def do_level
    begin
      call_block
    rescue Prune
      return
    end
    scan_dir
  end

  def do_level_depth
    begin
      path, fullpath = @path, @fullpath
      scan_dir
    ensure
      @path, @fullpath = path, fullpath
    end
    begin
      call_block
    rescue Prune
      raise RuntimeError, "#{self.class}: prune doesn't work with :depth."
    end
  end

  def call_block
    set_predefs name, count
    @block.call self
  end

  def set_predefs l, n
    b = @block.binding
    b.local_variable_set "_", [ l, n]
    b.eval "$_, $. = *_"
  end

  def read_dir
    handle_error Errno::EACCES do
      Dir.new @path
    end
  end

  def scan_dir
    return unless File.directory? @path
    if File.symlink? @path then
      return unless @follow and handle_error do
        d = @path
        while d != Dir::CUR_DIR do
          d, = File.split d
          raise "circular recursion in #@path" if File.identical? d, @path
        end
        true
      end
    end
    dir = (read_dir or return).children
    if @sort.respond_to? :call then
      dir = dir.sort_by &@sort
    elsif @sort and @sort.nonzero? then
      dir.sort!
      dir.reverse! if @sort < 0
    end
    dir.each { |f|
      f.freeze
      begin
        @levels.push f
        walk
      ensure
        @levels.pop
      end
    }
  end

  def handle_error err = nil
    yield
  rescue err||StandardError
    if @error.respond_to? :call then
      @error.call
    elsif @error then
      instance_eval @error
    else
      raise
    end
    nil
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
          if    (m & 04000).nonzero? then  9
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

  class <<self
    def find *args
      raise NotImplementedError, "This is not the standard Find."
    end
  end

end

