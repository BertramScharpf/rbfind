#
#  rbfind/csv.rb  --  Write CSV-like output
#


module RbFind

  module Csv

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
      Csv.putl e
    end


    @outfile = $stdout

    class <<self
      def putl l
        @outfile << l << $/
      end
      def outfile out
        o, @outfile = @outfile, out
        yield
      ensure
        @outfile = o
      end
    end

  end

end

