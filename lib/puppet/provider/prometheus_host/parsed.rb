require 'puppet/provider/parsedfile'
require 'json'

Puppet::Type.type(:prometheus_host).provide(
  :parsed,
  :parent => Puppet::Provider::ParsedFile,
  :filetype => :flat,
  :default_target => "/etc/prometheus/prometheus_host.json"
) do
  desc "Parse and generate JSON files for prometheus based on prometheus_host exporters."

  record_line :parsed,
    :fields     => %w{host_name port},
    :optional   => %w{labels},
    :block_eval => :instance do

    def to_line(record)
      rhash = {}
      rhash.merge!(targets: "#{record[:host_name]}:#{record[:port]}")
      rhash.delete(:host_name)
      rhash.delete(:port)

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

  def self.parse_line(line)
    rtn = {}

    clean_line = line.tr("[]\n\t","")
    JSON.parse(clean_line).each do |k,v|
      rtn[k] = v
    end

    rtn
  end

  #def self.parse_line(line)
  #  fmt_line = line.tr("[]", "")
  #  rtn = JSON.parse(fmt_line)
  #  rtn[:host_name] = rtn['targets'].split(':')[0]
  #  rtn[:port] = rtn['targets'].split(':')[1]
  #  rtn.delete('targets')
  #  puts rtn.inspect
  #  rtn
  #end

  def self.to_file(records)
    text = records.collect { |record| self.to_line(record) }.join(self.line_separator)

    #text += line_separator if self.trailing_separator

    "[\n\t#{text}\n]\n"
  end
end
