require 'puppet'
require 'puppet/provider/parsedfile'
require_relative '../external/prometheus'
require 'json'

# The base class for all Prominator providers.
class Puppet::Provider::Prominator < Puppet::Provider::ParsedFile
  NAME_STRING = "## --PUPPET_NAME-- (called '_prominator_name' in the manifest)"
  # Retrieve the associated class from Prometheus::Base.
  def self.prometheus_type
    unless @prometheus_type
      name = resource_type.name.to_s.sub(/^prometheus_/, '')
      unless @prometheus_type = Prometheus::Base.type(name.to_sym)
        raise Puppet::DevError, "Could not find prometheus type '#{name}'"
      end

      # And add our 'ensure' settings, since they aren't a part of
      # Prominator by default
      @prometheus_type.send(:attr_accessor, :ensure, :target, :on_disk)
    end
    @prometheus_type
  end

  def self.parse(text)
      Prometheus::Parser.new.parse(text.gsub(NAME_STRING, "_prominator_name"))
  rescue => detail
      raise Puppet::Error, "Could not parse configuration for #{resource_type.name}: #{detail}", detail.backtrace
  end

  def self.to_file(records)
    file_records = [ ]
    records.collect { |record| 
      file_records.push(record.to_hash)
    }
    JSON.generate(file_records)
  end

  def self.skip_record?(record)
    false
  end

  def self.valid_attr?(klass, attr_name)
    prometheus_type.parameters.include?(attr_name)
  end

  def initialize(resource = nil)
    if resource.is_a?(Prometheus::Base)
      # We don't use a duplicate here, because some providers (ParsedFile, at least)
      # use the hash here for later events.
      @property_hash = resource
    elsif resource
      @resource = resource if resource
      # LAK 2007-05-09: Keep the model stuff around for backward compatibility
      @model = resource
      @property_hash = self.class.prometheus_type.new
    else
      @property_hash = self.class.prometheus_type.new
    end
  end
end
