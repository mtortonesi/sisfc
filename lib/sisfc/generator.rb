require 'csv'
require 'sisfc/request'


module SISFC

  class RequestGenerator

    def initialize(opts)
      if opts.has_key? :filename
        @file = File.open(opts[:filename], mode='r')

        # open trace file
        raise "File #{opts[:filename]} does not exist!" unless File.exists? opts[:filename]
      elsif opts.has_key? :command
        @file = IO.popen(opts[:command])
      else
        raise ArgumentError, 'Need to provide either a filename or a command!'
      end

      # throw away the first line (containing the CSV headers)
      @file.gets

      # NOTE: so far we support only sequential integer rids
      @next_rid = 0

      setup_finalizer
    end


    def generate
      # read next line from file
      line = @file.gets
      raise "End of input reached while reading request #{@next_rid}!" unless line

      # parse data
      tokens = line.parse_csv
      generation_time  = tokens[0].to_f
      data_center_id   = tokens[1].to_i
      arrival_time     = tokens[2].to_f
      workflow_type_id = tokens[3].to_i

      # increase @next_rid
      @next_rid += 1

      # sanity check
      if generation_time > arrival_time
        raise "Generation time (#{generation_time}) is larger than arrival time (#{arrival_time})!"
      end

      # generate and return request
      Request.new(@next_rid,
                  generation_time,
                  data_center_id,
                  arrival_time,
                  workflow_type_id)
    end


    private
      # After object destruction, make sure that the input file is closed or
      # the input command process is killed.
      def setup_finalizer
        ObjectSpace.define_finalizer(self, self.class.close_io(@file))
      end

      # Need to make this a class method, or the deallocation won't take place. See:
      # http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
      def self.close_io(file)
        Proc.new do
          if file.respond_to? :pid
            Process.kill('INT', file.pid)
          elsif
            file.close
          end
        end
      end
  end

end
