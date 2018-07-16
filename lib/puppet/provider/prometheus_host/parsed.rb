require 'puppet/provider/parsedfile'
require 'json'

Puppet::Type.type(:prometheus_host).provide(
  :parsed,
  :parent => Puppet::Provider::ParsedFile,
  :filetype => :flat
) do
  desc "Parse and generate JSON files for prometheus based on prometheus_host exporters."

  record_line :parsed,
    :fields     => %w{host_name port},
    :optional   => %w{labels},
    :block_eval => :instance do

    def to_line(record)
      rhash = {}
      rhash.merge!(targets: "#{record[:host_name]}:#{record[:port]}")

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

  def self.to_file(records)
    text = records.collect { |record| self.to_line(record) }.join(self.line_separator)

    text += line_separator if self.trailing_separator

    "[\n\t#{text}\n]"
  end

  def self.default_target
    "/etc/prometheus/prometheus_host.json"
  end
end
