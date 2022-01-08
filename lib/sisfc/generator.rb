# frozen_string_literal: true

module SISFC
  class RequestGenerator
    def initialize(opts = {})
      if opts.key? :filename
        raise ArgumentError, "File #{opts[:filename]} does not exist!" unless File.exist?(opts[:filename])

        @file = File.open(opts[:filename], 'r')
      elsif opts.key? :command
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
      tokens = line.split(',') # should be faster than CSV parsing
      generation_time  = tokens[0].to_f
      workflow_type_id = tokens[1].to_i
      customer_id      = tokens[2].to_i

      # increase @next_rid
      @next_rid += 1

      # return request
      { rid: @next_rid, 
        generation_time: generation_time, 
        workflow_type_id: workflow_type_id, 
        customer_id: customer_id }
    end

    # Need to make this a class method, or the deallocation won't take place. See:
    # http://www.mikeperham.com/2010/02/24/the-trouble-with-ruby-finalizers/
    def self.close_io(file)
      proc do
        if file.pid.nil?
          file.close
        else
          Process.kill('INT', file.pid)
        end
      end
    end

    private

    # After object destruction, make sure that the input file is closed or
    # the input command process is killed.
    def setup_finalizer
      ObjectSpace.define_finalizer(self, self.class.close_io(@file))
    end
  end
end
