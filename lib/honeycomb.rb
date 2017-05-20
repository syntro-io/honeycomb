require 'honeycomb/ir'

# Honeycomb API
module Honeycomb

  @data = []

  # Report Honeycomb IR to a test repository or similar
  def self.submit_results(args)
    reporter_class = Honeycomb.reporter_class(args[:reporter])
    reporter = reporter_class.new( args )

    ir = Honeycomb::IR.load(args[:ir])

    reporter.submit_results( ir, args )
  end

  def self.reporter_class(type)
    case type
      when :test_rail
        require 'honeycomb/reporters/test_rail'
        Honeycomb::Reporters::TestRail
      when :hive
        require 'honeycomb/reporters/hive'
        Honeycomb::Reporters::Hive
      when :testmine
        require 'honeycomb/reporters/testmine'
        Honeycomb::Reporters::Testmine
      when :lion
        require 'honeycomb/reporters/lion'
        Honeycomb::Reporters::Lion
      else 
        raise "Invalid Reporter type"
    end
  end

  def self.parse_results(args)
    parser_class = Honeycomb.parser_class(args[:parser])
    parser_class.new(args[:file])
  end

  def self.parser_class(type)
    case type
      when :junit
        require 'honeycomb/parsers/junit'
        Honeycomb::Parsers::Junit
      when :junitcasper
        require 'honeycomb/parsers/junitcasper'
        Honeycomb::Parsers::Junitcasper
      else
        raise "#{type} parser not Implemented"
    end
  end

  def self.perf_data
    @data
  end

  def self.perf_data= data
    @data = data
  end

end
