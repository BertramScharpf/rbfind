#
#  rbfind/appl.rb  --  Option parsing etc.
#


module RbFind

  class Application

    class Exit < Exception ; end

    class OptError < StandardError
      def initialize opt
        super "Unknown option: #{opt}"
      end
    end


    class <<self

      def inherited cls
        cls.init_opts
      end

      attr_reader :options
      attr_accessor :debug

      def init_opts
        @options, @optdocs = {}, []
      end

      def option names, doc, &block
        names.each { |n| @options[ n] = block }
        @optdocs.push [ names, doc]
      end

      def run
        exit (new $*).run.to_i
      rescue Exit
        exit 0
      rescue OptError
        $stderr.puts $!
        usage
        exit 15
      rescue
        raise if @debug
        $stderr.puts $!
        exit 1
      end

      def usage
        omax, amax, l = 0, 0, []
        @optdocs.each { |names,desc|
          m = names.map { |n| (n.length > 1 ? "--" : "-") + n }.join " "
          omax = m.length if m.length > omax
          _, arg = @options[ names.first].parameters.first
          if arg then
            a = arg.upcase
            amax = a.length if a.length > amax
          end
          l.push [ m, a, desc]
        }
        l.push [ "--", nil, "stop option processing"]
        fmt = "    %%-%ds  %%-%ds  %%s" % [ omax, amax]
        l.each { |mad| puts fmt % mad }
      end

      def process_options args
        rest = []
        loop do
          arg, *args = *args
          arg or break
          if arg =~ /^-/ then
            arg = $'
            if arg =~ /^-/ then
              arg = $'
              if arg.empty? then
                rest.concat args
                break
              end
              arg, val = arg.split "=", 2
              opt = @options[ arg] or raise OptError, "--#{arg}"
              if val then
                opt.parameters.empty? and raise OptError, "--#{args}=value"
                yield opt, val
              else
                unless opt.parameters.empty? then
                  if opt.arity.nonzero? or args.first !~ /^-/ then
                    arg, *args = *args
                  else
                    arg = nil
                  end
                end
                yield opt, arg
              end
            else
              loop do
                a = arg.slice! 0, 1
                a.empty? and break
                opt = @options[ a] or raise OptError, "-#{a}"
                if opt.parameters.empty? then
                  yield opt
                else
                  if arg.empty? then
                    if opt.arity.nonzero? or args.first !~ /^-/ then
                      arg, *args = *args
                    end
                  end
                  yield opt, arg
                  break
                end
              end
            end
          else
            rest.push arg
          end
        end
        rest
      end

    end

    def initialize args
      @args = self.class.process_options args do |opt,arg|
        if arg then
          instance_exec arg, &opt
        else
          instance_exec &opt
        end
      end
    end

  end


  if __FILE__ == $0 then

    class DummyAppl < Application

      option %w(q qqq),   "Do Qs"      do @q = @q.to_i.pred end
      option %w(x xxx),   "Do Xs"      do @x = @x.to_i.succ end
      option %w(y yyy),   "Do Ys"      do |arg| @y = arg end
      option %w(z zzz),   "Do Zs"      do |arg=3| @z = arg end
      option %w(h help),  "This help"  do self.class.usage ; raise Exit ; end
      option %w(g debug), "Debug info" do self.class.debug = true end

      def run
        puts inspect
      end

    end

    DummyAppl.run

  end

end

