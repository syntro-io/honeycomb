# Formatter for ruby cucumber

require 'fileutils'
require 'honeycomb'
require 'honeycomb/ir'
require 'cucumber/formatter/io'
require 'cucumber/formatter/summary'

module Honeycomb
  module Formatters
    class RubyCucumber2
      include FileUtils
      include ::Cucumber::Formatter::Io
     
      def initialize(runtime, path_or_io, options)
        @runtime = runtime
        begin
          @io = ensure_io(path_or_io) 
        rescue
          @io = ensure_io(path_or_io, '')
        end
        @options = options
        @exceptions = []
        @indent = 0
        @prefixes = options[:prefixes] || {}
        @delayed_messages = []
        @_start_time = Time.now
      end

      def before_features(features)
        @_features = []
      end

      # Once everything has run -- whack it in a HoneycombultIR object and
      # dump it as json
      def after_features(features)
        results = @_features
        ir = ::Honeycomb::IR.new( :started     => @_start_time,
                            :finished    => Time.now(),
                            :results     => results,
                            :type        => 'Cucumber' )
        @io.puts ir.json
      end

      def before_feature(feature)
        @_feature = {}
        @_context = {}
        @_feature[:started] = Time.now()
        begin
          hash = RubyCucumber2.split_uri( feature.location.to_s )
          @_feature[:file] = hash[:file]
          @_feature[:line] = hash[:line]
          @_feature[:urn]  = hash[:urn]
        rescue
          @_feature[:uri] = 'unknown'
        end
        @_features << @_feature
        @_context = @_feature
      end

      def comment_line(comment_line)
        @_context[:comments] = [] if !@_context[:comments]
        @_context[:comments] << comment_line 
      end

      def after_tags(tags)
      end

      def tag_name(tag_name)
        @_context[:tags] = [] if !@_context[:tag]
        # Strip @ from tags
        @_context[:tags] << tag_name[1..-1]
      end

      # { :type => 'Feature',
      #   :name => 'Feature name',
      #   :description => "As a blah\nAs a blah\n" }
      def feature_name(keyword, name)
        @_feature[:type] = "Cucumber::" + keyword.gsub(/\s+/, "")

        lines = name.split("\n")
        lines = lines.collect { |l| l.strip }

        @_feature[:name] = lines.shift
        @_feature[:description] = lines.join("\n")
      end

      def after_feature(feature)
        @_feature[:finished] = Time.now()
      end

      def before_feature_element(feature_element)

        @_feature_element = {}
        @_context = {}
        @_feature_element[:started] = Time.now
        begin
          hash = RubyCucumber2.split_uri( feature_element.location.to_s )
          @_feature_element[:file] = hash[:file]
          @_feature_element[:line] = hash[:line]
          @_feature_element[:urn] = hash[:urn]
        rescue => e
          @_feature_element[:error] = e.message
          @_feature_element[:file] = 'unknown'
        end

        @_feature[:children] = [] if ! @_feature[:children]

        @_feature[:children] << @_feature_element
        @_context = @_feature_element
      end

      # After a scenario
      def after_feature_element(feature_element)
        @_context = {}

        scenario_class = Cucumber::Formatter::LegacyApi::Ast::Scenario
        example_table_class = Cucumber::Core::Ast::Location

        fail =  @runtime.scenarios(:failed).select do |s|
          [scenario_class, example_table_class].include?(s.class)
        end.map do |s|
          if s.location.file == feature_element.location.file
            s
          end          
        end

        if fail.compact.empty? and feature_element.respond_to? :status
          @_feature_element[:status] = feature_element.status if feature_element.status.to_s != "skipped"
        else
          fail = fail.compact
          @_feature_element[:status] = fail[0].status
        end

        @_feature_element[:finished] = Time.now
        @_feature_element[:values] = Honeycomb.perf_data.pop if !Res.perf_data.empty?
      end

      def before_background(background)
        #@_context[:background] = background
      end

      def after_background(background)
      end

      def background_name(keyword, name, file_colon_line, source_indent)
      end

      def examples_name(keyword, name)
      end


      def scenario_name(keyword, name, file_colon_line, source_indent)
        @_context[:type] = "Cucumber::" + keyword.gsub(/\s+/, "")
        @_context[:name] = name || ''
      end

      def before_step(step)
        @_step = {}

        # Background steps can appear totally divorced from scenerios (feature
        # elements). Need to make sure we're not including them as children
        # to scenario that don't exist
        return if @_feature_element && @_feature_element[:finished]

        @_feature_element = {} if !@_feature_element
        @_feature_element[:children] = [] if !@_feature_element[:children]
        @_feature_element[:children] << @_step
        @_context = @_step
      end

      def step_name(keyword, step_match, status, source_indent, background, *args)

        file_colon_line = args[0] if args[0]

        @_step[:type] = "Cucumber::Step"
        name = keyword + step_match.format_args(lambda{|param| %{#{param}}}) 
        @_step[:name] = name
        @_step[:status] = status
        #@_step[:background] = background
        @_step[:type] = "Cucumber::Step"

      end
        
      def exception(exception, status)
        @_context[:message] = exception.to_s
      end

      def before_multiline_arg(multiline_arg)
      end

      def after_multiline_arg(multiline_arg)
        @_context[:args] = multiline_arg.to_s.gsub(/\e\[(\d+)m/, '')
        @_table = nil
      end

      # Before a scenario outline is encountered
      def before_outline_table(outline_table)
        # Scenario outlines appear as children like normal scenarios,
        # but really we just want to construct normal-looking children
        # from them
        @_outlines = @_feature_element[:children]
        @_table = []
      end

      def after_outline_table(outline_table)
        headings = @_table.shift
        description = @_outlines.collect{ |o| o[:name] }.join("\n") + "\n" + headings[:name]
        @_feature_element[:children] = @_table
        @_feature_element[:description] = description
      end

      def before_table_row(table_row)
        @_current_table_row = { :type => 'Cucumber::ScenarioOutline::Example' }
        @_table = [] if !@_table
      end

      def after_table_row(table_row)
        if table_row.class == Cucumber::Formatter::LegacyApi::Ast::ExampleTableRow

          @_current_table_row[:name] = table_row.name
          if table_row.exception
            @_current_table_row[:message] = table_row.exception.to_s
          end

          if table_row.status and table_row.status != "skipped" and table_row.status != nil
            @_current_table_row[:status] = table_row.status
          end
            
          @_current_table_row[:line] = table_row.line
          @_current_table_row[:urn] = @_feature_element[:file] + ":" + table_row.line.to_s
          @_table << @_current_table_row
        end
      end

      def after_table_cell(cell)
      end

      def table_cell_value(value, status)
        @_current_table_row[:children] = [] if !@_current_table_row[:children]
        @_current_table_row[:children] << { :type => "Cucumber::ScenarioOutline::Parameter",
                                            :name => value, :status => status }
      end

      def self.split_uri(uri)
        strings = uri.rpartition(/:/)
        { :file => strings[0], :line => strings[2].to_i, :urn => uri }
      end

    end
  end
end
