# frozen_string_literal: true

require "irb"
require "set"
require "watchcat"

require_relative "reload/version"
require_relative "reload/command"

module IRB
  module Reload
    DEFAULT_PATTERN = /\.rb\z/.freeze
    DEFAULT_PATHS = ["lib"]
    WATCHCAT_FILTERS = {
      ignore_remove: true,
      ignore_access: true
    }.freeze

    class << self
      def start
        @changed_files = Set.new
        normalized_paths = normalize_paths(config[:paths] || DEFAULT_PATHS)

        @watcher&.stop if defined?(@watcher) && @watcher
        @watcher = Watchcat.watch(normalized_paths, filters: WATCHCAT_FILTERS) do |event|
          record_watchcat_event(event)
        end

        @watched_paths = normalized_paths
        true
      end

      def reload!
        @changed_files.each do |file|
          reload_file(file)
        end
        @changed_files.clear
      end

      def watched_paths
        @watched_paths || []
      end

      def config
        IRB.conf[:RELOAD] ||= {}
      end

      private

      def normalize_paths(paths)
        normalized = Array(paths).map(&:to_s).reject(&:empty?)
        normalized = [Dir.pwd] if normalized.empty?
        normalized
      end

      def record_changed_files(modified, added)
        (Array(modified) + Array(added)).uniq.each do |file|
          next if file.nil?
          next unless ruby_file?(file)

          record_file(file)
        end
      end

      def record_watchcat_event(event)
        return unless actionable_event?(event)

        paths = Array(event.paths)
        if event.kind.create?
          record_changed_files([], paths)
        else
          record_changed_files(paths, [])
        end
      end

      def actionable_event?(event)
        kind = event&.kind
        return false unless kind

        kind.create? || kind.modify? || kind.any?
      end

      def ruby_file?(file)
        File.extname(file) == ".rb"
      end

      def record_file(file)
        @changed_files.add(file)
      end

      def reload_file(file)
        old_verbose, $VERBOSE = $VERBOSE, nil
        Kernel.load(file)
        $stdout.puts "[irb-reload] Reloaded #{file}"
      rescue StandardError => e
        warn "[irb-reload] Failed to reload #{file}: #{e.class}: #{e.message}"
      ensure
        $VERBOSE = old_verbose
      end
    end
  end
end

IRB::Command.register(:reload!, IRB::Reload::Command)
IRB::Reload.start
