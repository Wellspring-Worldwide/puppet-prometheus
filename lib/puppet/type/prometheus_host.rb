require_relative 'prometheus'
require_relative 'prometheus/base'
require_relative '../provider/prominator'

module Puppet
  Type.newtype(:prometheus_host) do
    @doc = "Manage prometheus_host resources"
  
    ensurable

    newparam(:name) do
      isnamevar
      desc "Exporter name"

      validate do |value|
        raise Puppet::Error,_("Resource name cannot include whitespaces") if value =~ /\s/
      end 
    end

    newproperty(:host_name) do
      desc "Host name of the exporter"
    end

    newproperty(:labels) do
      desc "Hash of labels to apply to the exporter"
    end

    newproperty(:port) do
      desc "Port for the exporter to connect to"
    end
  
    # File path to place the resource information in
    newproperty(:target) do
      desc "The file in which to source the exporter information. Only used by
        the `parsed` provider."
    
      defaultto { if @resource.class.defaultprovider.ancestors.include?(Puppet::Provider::ParsedFile)
        @resource.class.defaultprovider.default_target
        else 
          nil
        end
      }
    end
  end
end
