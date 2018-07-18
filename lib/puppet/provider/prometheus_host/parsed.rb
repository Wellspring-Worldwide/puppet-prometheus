require 'puppet/provider/parsedfile'
require 'json'
#require 'pry'

Puppet::Type.type(:prometheus_host).provide(
  :parsed,
  :parent => Puppet::Provider::ParsedFile,
  :filetype => :flat,
  :default_target => "/etc/prometheus/prometheus_host.json"
) do
  desc "Parse and generate JSON files for prometheus based on prometheus_host exporters."

  attr_reader :name

  record_line "parsed",
    :fields     => %w{host_name port},
    :optional   => %w{labels},
    :block_eval => :instance do

    def to_line(record)
      rhash = {}
      rhash[:targets] = ["#{record[:host_name]}:#{record[:port]}"]

      if record[:labels]
        rhash.merge!(labels: record[:labels])
      end

      rhash.to_json
    end
  end

  def self.default_mode
    0644
  end

  def self.line_separator
    ",\n\t"
  end

#  def record_type(type)
#    @record_types[type]
#  end

  def self.handle_record_line(line, record)
    clean_line = line.tr("[]\n\t","")
    line_hash = JSON.parse(clean_line)
    ret = {}

    unless line_hash.is_a?(Hash)
      raise Puppet::DevError, _("Process record type %{record_name} returned non-hash.") % { record_name: record.name }
    end

    target_breakout = line_hash["targets"].split(':')

    line_hash["host_name"] = target_breakout[0]
    line_hash["port"] = target_breakout[1]
    line_hash.delete("targets")

    record.fields.each do |param|
      #puts param
      ret[param.intern] = line_hash[param.to_s]
    end

    ret[:labels] = line_hash["labels"]
    ret[:record_type] = record.name
    ret.inspect

    #binding.pry

    ret
  end


  #def self.parse_line(line)
  #  rtn = {}
#
  #  clean_line = line.tr("[]\n\t","")
  #  JSON.parse(clean_line).each do |k,v|
  #    rtn[k.intern] = v
  #  end
  #  rtn[:record_type] = "parsed"
  #  rtn.inspect
  #  binding.pry
  #  rtn
  #end

  def self.to_file(records)
    text = records.collect { |record| self.to_line(record) }.join(self.line_separator)

    #text += line_separator if self.trailing_separator

    "[\n\t#{text}\n]\n"
  end
end
