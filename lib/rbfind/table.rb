#
#  rbfind/table.rb  --  Table for data
#


module RbFind

  class Table

    def initialize *heads
      heads.flatten!
      @heads = heads.map { |h|
        a = case h
          when />\z/  then +1
          when /\^\z/ then  0
          when /<?\z/ then -1
        end
        [ $`, a]
      }
      @rows = []
    end

    attr_reader :heads
    protected :heads
    def initialize_copy oth
      @heads = oth.heads
      @rows = []
    end

    def add *row
      row.flatten!
      n = @heads.size
      row.map! { |r| break if n.zero? ; n -= 1 ; r.to_s }
      @rows.push row
    end

    def sort_by! *nums
      @rows.sort_by! { |x| nums.map { |i| x[i] } }
    end

    def empty?
      @rows.empty?
    end

    def output head: false, ifempty: nil
      if empty? and ifempty then
        puts ifempty
        return
      end
      make_lines head: head do |l| puts l end
    end

    def make_lines head: false
      rs = @rows
      rs.unshift @heads.map { |(h,a)| h } if head
      w = calc_widths
      rs.each { |r|
        j = (w.zip @heads, r).map { |v,(_,a),c|
          v ||= ""
          case a
            when -1 then c.ljust  v
            when  0 then c.center v
            when +1 then c.rjust  v
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
          @heads.each { |(h,a)|
            tag :td, h.downcase, align: a do @html << h end
          }
        end
        @rows.each { |r|
          tag :tr, table, nl: 1 do
            (@heads.zip r).each { |(g,a),c|
              tag :td, g.downcase, align: a do @html << c end
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
        w = (w.zip r).map { |i,c|
          if c then
            j = c.length
            i = j if j > i
          end
          i
        }
      }
      w
    end

    def tag name, cls, nl: 0, align: nil
      @html << "<#{name}"
      @html << " style=\"text-align: " << (html_align align) << ";\"" if align
      @html << " class=\"" << cls << "\"" if cls
      @html << ">"
      @html << $/ if nl > 1
      yield
      @html << "</#{name}>"
      @html << $/ if nl > 0
    end

    def html_align a
      case a
        when -1 then "left"
        when  0 then "center"
        when +1 then "right"
      end
    end

  end

end
