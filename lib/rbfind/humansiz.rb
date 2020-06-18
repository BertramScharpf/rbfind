#
#  humansiz.rb  --  Numeric class extensions for human readable sizes
#


=begin rdoc

Human readable sizes, times, and modes.

Examples:

  4096.to_h   # => "  4.1kB"
  4096.to_hib # => "   4.0kiB"
  1.MB        # => 1000000
  1.MiB       # => 1048576
  1.5.kiB     # => 1536.0

  1.h   # => 3600
  1.w   # => 604800

=end


class Numeric                   # sizes in bytes

  # :stopdoc:
  K = 1000
  M = K * K
  G = K * M
  T = K * G
  # :startdoc:

  def kB ; self * K ; end
  def MB ; self * M ; end
  def GB ; self * G ; end
  def TB ; self * T ; end


  # :stopdoc:
  Kb = 1024
  Mb = Kb * Kb
  Gb = Kb * Mb
  Tb = Kb * Gb
  # :startdoc:

  def kiB ; self * Kb ; end
  def MiB ; self * Mb ; end
  def GiB ; self * Gb ; end
  def TiB ; self * Tb ; end

  PREFIXES = " kMGTPEZY".scan /./   # :nodoc:

  # :call-seq:
  #    num.to_h()  -> str
  #
  # To human readable with decimal prefixes.
  #
  #   4096.to_h   #=> "  4.1kB"
  #
  def to_h
    n = 0
    s = to_f
    while s >= K do s /= K ; n += 1 end
    format = n.zero? ? "%3d  " : "%5.1f"
    (format % s) + (PREFIXES[ n]||"?") + "B"
  end

  # :call-seq:
  #    num.to_hib()  -> str
  #
  # To human readable with binary prefixes.
  #
  #   4096.to_hib   #=> "   4.0kiB"
  #
  def to_hib
    n = 0
    s = to_f
    while s >= Kb do s /= Kb ; n += 1 end
    format = n.zero? ? "%4d  " : "%6.1f"
    (format % s) + (PREFIXES[ n]||"?") + "iB"
  end

end


class Numeric
  "smhdw".each_char { |c|
    define_method c do Time.to_sec self, c end
  }
  def t ; Time.to_unit to_i ; end
end


class Time

  TIME_UNITS = [ "seconds", 60, "minutes", 60, "hours", 24, "days", 7, "weeks", ]
  class <<self
    def to_unit n
      u = TIME_UNITS.each_slice 2 do |nam,val|
        break nam if not val or n < val
        n /= val
      end
      "#{n}#{u[0]}"
    end
    def to_sec num, unit
      TIME_UNITS.each_slice 2 do |nam,val|
        return num if nam.start_with? unit
        num *= val
      end
      raise "No time unit: #{unit}."
    end
    def str_to_sec str
      str =~ /(\d*) *(\w*)/
      to_sec $1.to_i, $2
    end
  end

  # :call-seq:
  #    time.lsish()  -> str
  #
  # Build a time string like in <code>ls -l</code>. When the year is
  # the current, show the time. While <code>ls</code> doesn't show
  # the seconds, this will allways include them.
  #
  #   Time.now.lsish           #=> " 8. Oct 15:15:19"
  #   file.stat.mtime.lsish    #=> " 1. Apr 2008    "
  #
  def lsish
    strftime "#{PERC_DAY}. %b " +
              (year == Time.now.year ? "%H:%M:%S" : "%Y    ")
  end

  # Windows has no "%e".
  PERC_DAY = Time.now.strftime("%e") =~ /\d/ ? "%e" : "%d"   # :nodoc:

end


class Integer
  def hex
    to_s 0x10
  end
  def oct
    to_s 010
  end
  def bin
    to_s 0b10
  end
end

