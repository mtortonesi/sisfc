module SISFC

  class DataCenter

    def initialize(id, opts)
      @dcid      = id
      @available = opts[:maximum_vm_capacity]
      @capacity  = @available.dup.freeze
      @vms       = {}
    end

    def add_vm(vm, component_name)
      @vms[component_name] ||= []

      raise 'Error! VM is already present!' if @vms[component_name].include? vm

      # return an error code if we don't have any more VMs available
      return false unless @available[vm.size] > 0

      # allocate VM
      @available[vm.size] -= 1
      @vms[component_name] << vm
    end

    def remove_vm(vm, component_name)
      if @vms.has_key? component_name and @vms[component_name].include? vm
        @available[vm.size] += 1
        @vms.delete(vm)
      end
    end

    # returns nil in case no VM for component component_name is running
    def get_random_vm(component_name)
      if @vms.has_key? component_name
        @vms[component_name].sample
      end
    end

    def get_number_of_vms(component_name)
      @vms.has_key? component_name ? @vms[component_name].size : 0
    end

    def available(vm_size)
      @available[vm_size]
    end

    def to_s
      "Data center #{@dcid}, with VMs:" +
        @vms.inject("") {|s,(k,v)| s += " (#{k}: #{v.size})" }
    end

  end

end
