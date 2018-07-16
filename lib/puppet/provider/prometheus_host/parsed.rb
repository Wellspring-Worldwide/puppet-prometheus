require 'puppet/provider/parsedfile'

Puppet::Type.type(:prometheus_host).provide(
  :parsed,
  :parent => Puppet::Provider::ParsedFile,
  :filetype => :flat
) do
  desc "Parse and generate JSON files for prometheus based on prometheus_host exporters."

  record_line :parsed, :fields => %w{host_name labels port},
    :post_parse => proc { |hash|
      puts hash
    },
    :pre_gen => proc { |hash|
      puts hash
    }

  def self.default_mode
    0644
  end

  def self.default_target
    "/etc/prometheus/prometheus_host.json"
  end
end
