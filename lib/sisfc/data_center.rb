module SISFC

  class DataCenter

    def initialize(id, opts)
      @dcid      = id
      @capacity  = opts[:maximum_vm_capacity]
      @available = @capacity.dup
      @vms       = {}
    end

    def add_vm(vm, component_name)
      @vms[component_name] ||= []
      raise 'Error! VM is already present!' if @vms[component_name].include? vm
      if @available[vm.size] > 0
        @available[vm.size] -= 1
      else
        raise 'Error! VM capacity exceeded!'
      end
      @vms[component_name] << vm
    end

    def remove_vm(vm, component_name)
      unless @vms.has_key? component_name
        raise "Error! Service component type #{component_name} not present in data center #{@dcid}!"
      end
      unless @vms[component_name].include? vm
        raise 'Error! VM not present!'
      end
      @available[vm.size] += 1
      @vms.delete(vm)
    end

    def get_random_vm(component_name)
      unless @vms.has_key? component_name
        raise "Error! Service component type #{component_name} not present in data center #{@dcid}!"
      end
      @vms[component_name].sample
    end

    def get_number_of_vms(component_name)
      unless @vms.has_key? component_name
        raise "Error! Service component type #{component_name} not present in data center #{@dcid}!"
      end
      @vms[component_name].size
    end

    def available(size)
      @available[size]
    end

    def to_s
      "Data center #{@dcid}, with VMs:" +
        @vms.inject("") {|s,(k,v)| s += " (#{k}: #{v.size})" }
    end

  end

end
