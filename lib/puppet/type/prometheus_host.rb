require 'facter'

module Puppet
  Type.newtype(:prometheus_host) do
    @doc = "Manage prometheus_host resources"
    ensurable

    newparam(:name, :namevar => true) do
      desc 'Puppet catalog name of the prometheus exporter'
    end

    newproperty(:host_name) do
      desc "Host name of the exporter"
      defaultto Facter.value(:fqdn)
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

      defaultto "/etc/prometheus/prometheus_host.json"
    end

    def generate
      props = { :name => "/etc/prometheus/prometheus_host.json", :owner => 'root', :group => 'root', :mode => '0644' }
      Puppet::Type.type(:file).new(props)
    end
  end
end
