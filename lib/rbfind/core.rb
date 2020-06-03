#
#  rbfind/core.rb  --  Additional core functions
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


