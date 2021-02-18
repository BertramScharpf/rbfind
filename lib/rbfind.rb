#
#  rbfind.rb  --  Find replacement with many features
#

require "rbfind/core"
require "rbfind/csv"


module RbFind

  VERSION = "2.5".freeze

=begin rdoc

== Usage

See the README file or "rbfind -h" for a documentation of the command line
tool.

In Ruby programs, you may call:

    RbFind.run                do puts path end
    RbFind.run "dir"          do puts path end
    RbFind.run "dir1", "dir2" do puts path end
    RbFind.run %w(dir1 dir2)  do puts path end
    RbFind.run "dir", :max_depth => 3 do puts path end


== File properties

    name          # file name (*)
    path          # file path relative to working directory (*)
    fullpath      # full file path (*)
    path!         # directories with a slash appended (*)
    fullpath!     # directories with a slash appended (*)
    dirname       # dirname of path
    ext           # file name extension
    without_ext   # file name without extension
    depth         # step depth
    hidden?       # filename starting with "." (No Windows version, yet.)
    visible?      # not hidden?
    stat          # file status information (File::Stat object)
    mode          # access mode (like 0755, 0644)
    mtime         # modify time (atime, ctime as well)
    mage          # age in seconds since walk started
    age           # alias for mage
    user          # owner
    owner         # dto. (alias)
    group         # group owner
    user!         # owner, "." if process owner
    owner!        # dto. (alias)
    group!        # group owner, "." if process owner
    readlink      # symlink pointer or nil (*)
    broken_link?  # what you expect
    arrow         # ls-style "-> symlink" suffix (*)

                  # (*) = colored version available (see below)

    empty?               # directory is empty
    entries              # directory entries

    open  { |o| ... }    # open file
    read n = nil         # read first n bytes, nil reads to eof
    lines { |l,i| ... }  # open file and yield each |line,lineno|
    grep re              # lines with `l =~ re and colsep path, i, l'
    binary? n = 1   # test whether first n blocks contain null characters
    bin?            # alias for binary?

    vimswap?      # it is a Vim swapfile

Further will be redirected to the stat object (selective):

    directory?
    executable?
    file?
    pipe?
    socket?
    symlink?

    readable?
    writable?
    size
    zero?

    uid
    gid
    owned?
    grpowned?

    dir?         # alias for directory?

Derivated from stat:

    stype        # one-letter (short) version of ftype
    modes        # rwxr-xr-x style modes

    filesize                    # returns size for files, else nil
    filesize { |s| s > 1024 }   # returns block result for files


== Actions

    done    # exit from current entry
    done!   # dto.
    prune   # do not descend directory; abort current entry
    prune!  # dto.
    no_vcs  # omit .svn, CVS and .git directories
    novcs   # dto.

    colsep path, ...   # output parameters in a line separated by colons
    col_sep            #   dto. (alias)
    tabsep path, ...   # separate by tabs
    tab_sep            #
    spcsep path, ...   # separate by spaces
    spc_sep            #
    spacesep path, ... #
    space_sep          #
    p                  # alias for space_sep
    csv sep, path, ... # separate by user-defined separator

    rename newname   # rename, but leave it in the same directory
    mv newname       # dto.
    rm               # remove


== Color support

    cname       # colorized name
    cpath       # colorized path
    cpath!      # colorized path!
    cfullpath   # colorized fullpath
    cfullpath!  # colorized fullpath!
    creadlink   # colored symlink pointer
    carrow      # colored "-> symlink" suffix

    color arg   # colorize argument
    colour arg  # alias

    RbFind.colors str      # define colors
    RbFind.colours str     # alias

    Default color setup is "xxHbexfxcxdxbxegedabagacadAx".
    In case you did not call RbFind::Walk.colors, the environment variables
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

    suffix      # ls-like suffixes |@=/%* for pipe, ..., executable


== Encoding issues

Ruby raises an ArgumentError if, for example, an ISO8859-1-encoded
string gets read in as UTF-8-encoded and then is matched against a
UTF-8-encoded regular expression. This will happen if you are
running RbFind::Walk from an environment with something like
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

    RbFind.run do puts path end

Omit version control:

    RbFind.run "myproject" do
      prune if name == ".svn"
      puts path
    end

    # or even
    RbFind.run "myproject" do
      novcs
      puts path
    end

Mention directory contents before directory itself:

    RbFind.run "myproject", depth_first: true do
      puts path
    end

Limit search depth:

    RbFind.run max_depth: 2 do
      puts path
    end

Unsorted (alphabetical sort is default):

    RbFind.run sort: false do
      puts path
    end

Reverse sort:

    RbFind.run sort: true, reverse: true do
      puts path
    end

Sort without case sensitivity and preceding dot:

    s = proc { |x| x =~ /^\.?/ ; $'.downcase }
    RbFind.run sort: s do
      puts path
    end

=end

  class Found

    attr_reader :wd, :start, :count
    attr_reader :depth, :name, :path

    def initialize
      @wd, @start, @count = Dir.getwd, Time.now, 0
    end

    def run
      @name, @depth = nil, 0
      yield
    ensure
      @name = @depth = nil
    end

    def step list
      list.each do |f|
        @depth += 1
        enter f do
          yield
        end
      ensure
        @depth -= 1
      end
    end

    def enter filename
      n_ = @name
      @name = filename.dup.freeze
      @dir = @path
      p_ = @path
      @path = join_path
      @count += 1
      yield
    ensure
      @path = p_
      @name = n_
    end

    def replace name
      @name = name.dup.freeze
      @path = join_path
    end

    private

    def join_path
      r = name
      r = (File.join @dir, r).freeze if @dir
      r
    end

  end

  class Done  < Exception ; end
  class Prune < Exception ; end

  class <<self
    def run *args, **params, &block
      Walk.run *args, **params, &block
    end
  end

  class Walk

    class <<self
      def run *args, **params, &block
        i = new **params, &block
        i.run *args
        i.found.count
      end
    end

    attr_reader :found

    private

    def initialize max_depth: nil, depth_first: nil, follow: nil,
                            sort: true, reverse: false, error: nil, &block
      @max_depth = max_depth
      @depth_first = depth_first
      @follow = follow
      @sort = sort_parser sort, reverse
      @error = error
      @block = block

      ostat = $stdout.stat
      @ostat = ostat if ostat.file?

      @found = Found.new
    end

    def sort_parser st, rev
      r = case st
        when Proc                then proc { |l| l.sort_by! &st }
        when nil, false, nil, "" then proc { }
        else                          proc { |l| l.sort! }
      end
      rev ? proc { |l| r.call l ; l.reverse! } : r
    end

    public

    def run *args
      @found.run {
        args.flatten!
        args.compact!
        if args.empty? then
          visit_dir Dir::CUR_DIR
        else
          args.each { |base|
            handle_error do
              File.lstat base rescue raise "`#{base}` doesn't exist."
              @found.enter base do
                visit_depth
              end
            end
          }
        end
      }
    end

    private

    def visit_dir dir
      return if @max_depth and @max_depth == @found.depth
      list = (Dir.new dir).children
      @sort.call list
      @found.step list do
        visit_depth
      end
    end

    def visit_depth
      if @depth_first then
        enter_dir
        call_block or raise "#{self.class}: prune doesn't work with :depth_first."
      else
        call_block and enter_dir
      end
    end

    def enter_dir
      return unless File.directory? @found.path
      if File.symlink? @found.path then
        return unless @follow and handle_error do
          d = @found.path.dup
          while d != Dir::CUR_DIR do
            d, = File.split d
            raise "cyclic recursion in #{@found.path}" if File.identical? d, @found.path
          end
          true
        end
      end
      handle_error do
        visit_dir @found.path
      end
    end

    def call_block
      e = Entry.new @found.name, @found.path, @found
      handle_error do
        $_, $. = e.name, @found.count
        begin
          e.instance_eval &@block
        rescue Done
        end
        if e.name != @found.name then
          if e.name then
            e.name == (File.basename e.name) or
              raise "#{self.class}: rename to `#{e.name}' may not be a path."
            p = @found.path
            @found.replace e.name
            File.rename p, @found.path
          else
            if e.dir? then
              Dir.rmdir @found.path
            else
              File.unlink @found.path
            end
          end
        end
        true
      end
    rescue Prune
    end

    def handle_error
      yield
    rescue
      case @error
        when Proc   then @error.call
        when String then instance_eval @error
        else             raise
      end
      nil
    end

  end


  class Entry

    attr_reader :path, :name

    def initialize name, path, found
      @name, @path, @found = name, path, found
    end

    def depth ; @found.depth ; end
    def now   ; @found.start ; end

    def fullpath ; @fullpath ||= File.absolute_path @path, @found.wd ; end

    def stat  ; @stat  ||= File.lstat @path ; end
    def rstat ; @rstat ||= File.stat  @path ; end


    private
    def append_slash s ; (File.directory? s) ? (File.join s, "") : s ; end
    public

    def path!     ; append_slash path     ; end
    def fullpath! ; append_slash fullpath ; end

    def dirname
      File.basename File.dirname fullpath
    end


    def ext         ; File.extname name ; end
    def without_ext ; name[ /^(.+?)(?:\.[^.]+)?$/, 1 ].to_s ; end

    def hidden?  ; name =~ /^\./ ; end
    def visible? ; not hidden?   ; end


    def mode ; stat.mode ; end

    private
    def method_missing sym, *args, &block
      if stat.respond_to? sym then
        stat.send sym, *args, &block
      else
        super
      end
    end
    public

    def dir? ; stat.directory? ; end

    def aage ; @found.start - stat.atime ; end
    def mage ; @found.start - stat.mtime ; end
    def cage ; @found.start - stat.ctime ; end
    alias age mage

    # :call-seq:
    #    filesize => nil or int
    #    filesize { |size| ... } => obj
    #
    # Returns the files size. When the object is not a regular file,
    # nil will be returned or the block will not be called.
    #
    def filesize
      stat.file? or return
      if block_given? then
        yield stat.size
      else
        stat.size
      end
    end

    private
    def etc
      Etc
    rescue NameError
      require "etc" and retry
      raise
    end
    def get_user  u ; (etc.getpwuid u).name rescue u.to_s ; end
    def get_group g ; (etc.getgrgid g).name rescue g.to_s ; end
    public

    def user
      get_user stat.uid
    end
    alias owner user

    def user!
      u = stat.uid
      u == Process.uid ? "."  : (get_user u)
    end
    alias owner! user!

    def group
      get_group stat.gid
    end

    def group!
      g = stat.gid
      g == Process.gid ? "." : (get_group g)
    end


    def readlink ; File.readlink @path if stat.symlink? ; end

    def broken_link?
      return unless stat.symlink?
      rstat
      false
    rescue
      true
    end
    alias broken? broken_link?

    ARROW = " -> "
    def arrow
      ARROW + (File.readlink @path) if stat.symlink?
    end



    # :call-seq:
    #    empty?()     -> true or false
    #
    # Look up if the directory is empty. If the object is not a directory
    # or not accessible, +nil+ is returned.
    #
    def empty?
      (Dir.new @path).each_child { |f| return false }
      true
    rescue Errno::ENOTDIR
    end

    # :call-seq:
    #    contains?( name)     -> true or false
    #
    # Check whether a directory contains an entry.
    #
    def contains? name
      p = File.join @path, name
      File.lstat p
      true
    rescue
      false
    end

    # :call-seq:
    #    entries()     -> ary
    #
    # Return all entries in an array. If the object is not a directory,
    # +nil+ is returned.
    #
    def entries
      (Dir.new @path).children
    rescue Errno::ENOTDIR
    end
    alias children entries


    def vcs?
      %w(CVS .svn .git .hg .fslckout).include? name
    end


    # :call-seq:
    #    open() { |h| ... }    -> obj
    #
    # Open the file for reading. If the object is not a regular file,
    # nothing will be done.
    #
    def open &block
      @ostat and @ostat.identical? @path and
        raise "Refusing to open output file."
      File.open @path, &block if file?
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
          $_, $. = l, n
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
        color and l = "#$`\e[#{color}m#$&\e[m#$'"
        colsep @path, i, l
        true
      }
    end

    # :call-seq:
    #    binary?( n = 1)   -> true or false
    #
    # Test whether the first <code>n</code> blocks contain null characters.
    #
    def binary? n = 1
      bs = stat.blksize
      open { |file|
        loop do
          if n then
            break if n <= 0
            n -= 1
          end
          b = file.read bs
          b or break
          return true if b[ "\0"]
        end
      }
      false
    end
    alias bin? binary?

    def vimswap?
      if name =~ /\A(\..+)?\.sw[a-z]\z/i then
        mark = read 5
        mark == "b0VIM"
      end
    end



    def done  ; raise Done  ; end
    alias done! done

    def prune ; raise Prune ; end
    alias prune! prune

    def novcs
      prune if vcs?
    end
    alias no_vcs novcs


    include Csv


    def rename newname ; @name = newname ; end
    alias mv rename

    def rm ; @name = nil ; end


    def cname      ; color name      ; end
    def cpath      ; color path      ; end
    def cfullpath  ; color fullpath  ; end
    def cpath!     ; color path!     ; end
    def cfullpath! ; color fullpath! ; end

    def creadlink
      l = readlink
      if l then
        s = rstat rescue nil
        color_stat l, s
      end
    end

    def carrow
      r = creadlink
      ARROW + r if r
    end


    def color arg
      color_stat arg, stat
    end
    alias colour color

    private

    def color_stat arg, s
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
          if (m & 0111).nonzero? then
            if    (m & 04000).nonzero? then  9
            elsif (m & 02000).nonzero? then 10
            else                             6
            end
          else                               col_type or 0
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

    DEFAULT_COLORS = "xxHbexfxcxdxbxegedabagacadAx"

    class <<self

      def colored arg, num
        colors col_str
        "\e[#{@colors[num]}m#{arg}\e[m"
      end
      alias coloured colored

      def colors str
        @colors ||= if str =~ /:/ then
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

  end

end

