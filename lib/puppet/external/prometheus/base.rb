# The base class for all of our Prometheus object types.  Everything else
# is mostly just data.
class Prometheus::Base

  class UnknownPrometheusType < RuntimeError # When an unknown type is asked for by name.
  end

  include Enumerable

  class << self
    attr_accessor :parameters, :derivatives, :ocs, :name, :att
    attr_accessor :ldapbase

    attr_writer :namevar

    attr_reader :superior
  end

  # Attach one class to another.
  def self.attach(hash)
    @attach ||= {}
    hash.each do |n, v| @attach[n] = v end
  end

  # Convert a parameter to camelcase
  def self.camelcase(param)
    param.gsub(/_./) do |match|
      match.sub(/_/,'').capitalize
    end
  end

  # Uncamelcase a parameter.
  def self.decamelcase(param)
    param.gsub(/[A-Z]/) do |match|
      "_#{match.downcase}"
    end
  end

  # Create a new instance of a given class.
  def self.create(name, args = {})
    name = name.intern if name.is_a? String

    if @types.include?(name)
      @types[name].new(args)
    else
      raise UnknownPrometheusType, "Unknown type #{name}"
    end
  end

  # Yield each type in turn.
  def self.eachtype
    @types.each do |name, type|
      yield [name, type]
    end
  end

  # Create a mapping.
  def self.map(hash)
    @map ||= {}
    hash.each do |n, v| @map[n] = v end
  end

  # Return a mapping (or nil) for a param
  def self.mapping(name)
    name = name.intern if name.is_a? String
    if defined?(@map)
      @map[name]
    else
      nil
    end
  end

  # Return the namevar for the canonical name.
  def self.namevar
    if defined?(@namevar)
      return @namevar
    else
      if parameter?(:name)
        return :name
      elsif tmp = (self.name.to_s + "_name").intern and parameter?(tmp)
        @namevar = tmp
        return @namevar
      else
        raise "Type #{self.name} has no name var"
      end
    end
  end

  # Create a new type.
  def self.newtype(name, &block)
    name = name.intern if name.is_a? String

    @types ||= {}

    # Create the class, with the correct name.
    t = Class.new(self)
    t.name = name

    # Everyone gets this.  There should probably be a better way, and I
    # should probably hack the attribute system to look things up based on
    # this "use" setting, but, eh.
    t.parameters = [:use]

    const_set(name.to_s.capitalize,t)

    # Evaluate the passed block.  This should usually define all of the work.
    t.class_eval(&block)

    @types[name] = t
  end

  # Define both the normal case and camelcase method for a parameter
  def self.paramattr(name)
    camel = camelcase(name)
    param = name

    [name, camel].each do |method|
      define_method(method) do
        @parameters[param]
      end

      define_method(method.to_s + "=") do |value|
        @parameters[param] = value
      end
    end

  end

  # Is the specified name a valid parameter?
  def self.parameter?(name)
    name = name.intern if name.is_a? String
    @parameters.include?(name)
  end

  # Manually set the namevar
  def self.setnamevar(name)
    name = name.intern if name.is_a? String
    @namevar = name
  end

  # Set the valid parameters for this class
  def self.setparameters(*array)
    @parameters += array
  end

  # Set the superior ldap object class.  Seems silly to include this
  # in this class, but, eh.
  def self.setsuperior(name)
    @superior = name
  end

  # Parameters to suppress in output.
  def self.suppress(name)
    @suppress ||= []
    @suppress << name
  end

  # Whether a given parameter is suppressed.
  def self.suppress?(name)
    defined?(@suppress) and @suppress.include?(name)
  end

  # Return our name as the string.
  def self.to_s
    self.name.to_s
  end

  # Return a type by name.
  def self.type(name)
    name = name.intern if name.is_a? String

    @types[name]
  end

  # Convenience methods.
  def [](param)
    send(param)
  end

  # Convenience methods.
  def []=(param,value)
    send(param.to_s + "=", value)
  end

  # Iterate across all ofour set parameters.
  def each
    @parameters.each { |param,value|
      yield(param,value)
    }
  end

  # Initialize our object, optionally with a list of parameters.
  def initialize(args = {})
    @parameters = {}

    args.each { |param,value|
      self[param] = value
    }
    if @namevar == :_prominator_name
      self['_prominator_name'] = self['name']
    end
  end

  # Handle parameters like attributes.
  def method_missing(mname, *args)
    pname = mname.to_s
    pname.sub!(/=/, '')

    if self.class.parameter?(pname)
      if pname =~ /A-Z/
        pname = self.class.decamelcase(pname)
      end
      self.class.paramattr(pname)

      # Now access the parameters directly, to make it at least less
      # likely we'll end up in an infinite recursion.
      if mname.to_s =~ /=$/
        @parameters[pname] = args.first
      else
        return @parameters[mname]
      end
    else
      super
    end
  end

  # Retrieve our name, through a bit of redirection.
  def name
    send(self.class.namevar)
  end

  # This is probably a bad idea.
  def name=(value)
    unless self.class.namevar.to_s == "name"
      send(self.class.namevar.to_s + "=", value)
    end
  end

  def namevar
    (self.type + "_name").intern
  end

  def parammap(param)
    unless defined?(@map)
      map = {
        self.namevar => "cn"
      }
      map.update(self.class.map) if self.class.map
    end
    if map.include?(param)
      return map[param]
    else
      return "prometheus-" + param.id2name.gsub(/_/,'-')
    end
  end

  def parent
    unless defined?(self.class.attached)
      puts "Duh, you called parent on an unattached class"
      return
    end

    klass,param = self.class.attached
    unless @parameters.include?(param)
      puts "Huh, no attachment param"
      return
    end
    klass[@parameters[param]]
  end

  # okay, this sucks
  # how do i get my list of ocs?
  def to_ldif
    str = self.dn + "\n"
    ocs = Array.new
    if self.class.ocs
      # i'm storing an array, so i have to flatten it and stuff
      kocs = self.class.ocs
      ocs.push(*kocs)
    end
    ocs.push "top"
    oc = self.class.to_s
    oc.sub!(/Prometheus/,'prometheus')
    oc.sub!(/::/,'')
    ocs.push oc
    ocs.each { |objclass|
      str += "objectclass: #{objclass}\n"
    }
    @parameters.each { |name,value|
      next if self.class.suppress.include?(name)
      ldapname = self.parammap(name)
      str += ldapname + ": #{value}\n"
    }
    str += "\n"
  end

  def to_hash
    ret = { :targets => [ "#{self.host}:#{self.port}" ]}
    @parameters.keys.sort.each { |param|
      value = @parameters[param]
      puts "Key: #{param} - Value: #{value}"
      if ["host","port"].include?(param)
        next
      end
      ret.merge!( "#{param}" => value) 
    }
    exportername = "prometheus_#{self.name}_on_#{self.host}_port_#{self.port}"
    ret.merge!( "exporter_name" => exportername)
    ret
  end

  def to_s
    self.to_hash
  end

  # The type of object we are.
  def type
    self.class.name
  end

  # object types
  newtype :host do
    setparameters :exporter_name, :host, :labels, :port
    setnamevar :exporter_name
  end

end
