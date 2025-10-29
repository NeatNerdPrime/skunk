# frozen_string_literal: true

require "erb"
require "rubycritic/commands/status_reporter"
require "terminal-table"

module Skunk
  module Command
    # Knows how to report status for stinky files
    class StatusReporter < RubyCritic::Command::StatusReporter
      attr_accessor :analysed_modules

      def initialize(options = {})
        super(options)
      end

      HEADINGS = %w[file skunk_score churn_times_cost churn cost coverage].freeze
      HEADINGS_WITHOUT_FILE = HEADINGS - %w[file]
      HEADINGS_WITHOUT_FILE_WIDTH = HEADINGS_WITHOUT_FILE.size * 17 # padding

      TEMPLATE = ERB.new(<<-TEMPL
<%= _ttable %>\n
SkunkScore Total: <%= total_skunk_score %>
Modules Analysed: <%= analysed_modules_count %>
SkunkScore Average: <%= skunk_score_average %>
<% if worst %>Worst SkunkScore: <%= worst.skunk_score %> (<%= worst.pathname %>)<% end %>

Generated with Skunk v<%= Skunk::VERSION %>
TEMPL
                        )

      # Returns a status message with a table of all analysed_modules and
      # a skunk score average
      def update_status_message
        opts = table_options.merge(headings: HEADINGS, rows: table)

        _ttable = Terminal::Table.new(opts)

        @status_message = TEMPLATE.result(binding)
      end

      private

      def analysed_modules_count
        analysed_modules.analysed_modules_count
      end

      def worst
        analysed_modules.worst_module
      end

      def sorted_modules
        analysed_modules.sorted_modules
      end

      def total_skunk_score
        analysed_modules.skunk_score_total
      end

      def total_churn_times_cost
        analysed_modules.total_churn_times_cost
      end

      def skunk_score_average
        analysed_modules.skunk_score_average
      end

      def table_options
        max = sorted_modules.max_by { |a_mod| a_mod.pathname.to_s.length }
        width = max.pathname.to_s.length + HEADINGS_WITHOUT_FILE_WIDTH
        {
          style: {
            width: width
          }
        }
      end

      def table
        sorted_modules.map do |a_mod|
          [
            a_mod.pathname,
            a_mod.skunk_score,
            a_mod.churn_times_cost,
            a_mod.churn,
            a_mod.cost.round(2),
            a_mod.coverage.round(2)
          ]
        end
      end
    end
  end
end
