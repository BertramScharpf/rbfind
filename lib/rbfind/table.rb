#
#  rbfind/table.rb  --  Table for data
#


module RbFind

  class Table

    def initialize *heads
      heads.flatten!
      @heads = heads
      @rows = []
    end

    def spawn
      self.class.new *@heads
    end

    def add *row
      row.flatten!
      n = @heads.size
      row[ 0, n] = row[ 0, n].map { |r| r.to_s }
      @rows.push row
    end

    def sort_by! *nums
      @rows.sort_by! { |x| nums.map { |i| x[i] } }
    end

    def empty?
      @rows.empty?
    end

    def output head: false
      make_lines head: head do |l| puts l end
    end

    def make_lines head: false
      rs = @rows
      rs.unshift heads_plain if head
      w = calc_widths
      rs.each { |r|
        j = (w.zip @heads, r).map { |v,h,c|
          case h
            when />\z/  then c.rjust  v
            when /\^\z/ then c.center v
            when /<?\z/ then c.ljust  v
          end
        }
        l = j.join " "
        l.rstrip!
        yield l
      }
      nil
    end

    def make_html table: nil, row: nil
      @html = ""
      tag :table, table, nl: 2 do
        tag :tr, row, nl: 1 do
          (@heads.zip heads_plain).each { |h,c|
            tag :td, c.downcase, align: (html_align h) do @html << c end
          }
        end
        @rows.each { |r|
          tag :tr, table, nl: 1 do
            (@heads.zip heads_plain, r).each { |h,g,c|
              tag :td, g.downcase, align: (html_align h) do @html << c end
            }
          end
        }
      end
      @html
    ensure
      @html = nil
    end

    private

    def calc_widths
      w = @heads.map { 0 }
      @rows.each { |r|
        w = (w.zip r).map { |i,c| j = c.length ; j > i ? j : i }
      }
      w
    end

    def heads_plain
      @heads.map { |h| h.sub /\W\z/, "" }
    end

    def tag name, cls, nl: 0, align: nil
      @html << "<#{name}"
      @html << " style=\"text-align: " << align << ";\"" if align
      @html << " class=\"" << cls << "\"" if cls
      @html << ">"
      @html << $/ if nl > 1
      yield
      @html << "</#{name}>"
      @html << $/ if nl > 0
    end

    def html_align h
      case h
        when />/  then "right"
        when /\^/ then "center"
        when /<?/ then "left"
      end
    end

  end

end
