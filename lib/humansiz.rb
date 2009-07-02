#
#  humansiz.rb  --  human readable sizes
#
# Numeric class extensions for human readable sizes.

=begin rdoc

Human readable sizes and times.

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
  #
  #    num.to_h  => str
  #
  # To human readable with decimal prefixes.
  #
  #   4096.to_h   # => "  4.1kB"
  #
  def to_h
    n = 0
    s = to_f
    while s >= K do s /= K ; n += 1 end
    format = n.zero? ? "%3d  " : "%5.1f"
    (format % s) + (PREFIXES[ n]||"?") + "B"
  end

  # :call-seq:
  #
  #    num.to_hib  => str
  #
  # To human readable with binary prefixes.
  #
  #   4096.to_hib # => "   4.0kiB"
  #
  def to_hib
    n = 0
    s = to_f
    while s >= Kb do s /= Kb ; n += 1 end
    format = n.zero? ? "%4d  " : "%6.1f"
    (format % s) + (PREFIXES[ n]||"?") + "iB"
  end

end


class Numeric                   # time values
  def s ; self      ; end
  def m ; s    * 60 ; end
  def h ; m    * 60 ; end
  def d ; h    * 24 ; end
  def w ; d    *  7 ; end
end

