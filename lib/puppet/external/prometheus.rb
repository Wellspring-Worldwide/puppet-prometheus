#--------------------
# A script to retrieve hosts from ldap and create an importable
# cfservd file from them

require 'digest/md5'
#require 'ldap'
require 'puppet/external/prometheus/parser.rb'
require 'puppet/external/prometheus/base.rb'

module Prometheus
  PROMETHEUSVERSION = '2.3.0'
  # yay colors
  PINK = "[0;31m"
  GREEN = "[0;32m"
  YELLOW = "[0;33m"
  SLATE = "[0;34m"
  ORANGE = "[0;35m"
  BLUE = "[0;36m"
  NOCOLOR = "[0m"
  RESET = "[0m"

  def self.version
    PROMETHEUSVERSION
  end

  class Config
    def Config.import(config)

      text = String.new

      File.open(config) { |file|
        file.each { |line|
          text += line
        }
      }
      parser = Prometheus::Parser.new
      parser.parse(text)
    end

    def Config.each
      Prometheus::Object.objects.each { |object|
        yield object
      }
    end
  end
end
