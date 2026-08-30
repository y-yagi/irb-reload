# frozen_string_literal: true

require "irb"
require "set"
require "watchcat"

require_relative "reload/version"
require_relative "reload/command"

module IRB
  module Reload
    DEFAULT_PATHS = ["lib"]
    WATCHCAT_OPTIONS = {
      filters: { ignore_remove: true,ignore_access: true },
      patterns: [ "*.rb" ],
    }.freeze

    class << self
      def start
        @mutex = Mutex.new
        @changed_files = Set.new
        normalized_paths = normalize_paths(config[:paths] || DEFAULT_PATHS)

        @watcher&.stop if defined?(@watcher) && @watcher
        @watcher = Watchcat.watch(normalized_paths, **WATCHCAT_OPTIONS) do |event|
          record_watchcat_event(event)
        end

        @watched_paths = normalized_paths
        true
      end

      def reload!
        consume_changed_files.each do |file|
          reload_file(file)
        end
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
          record_file(file) unless file.nil?
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

      def record_file(file)
        @mutex.synchronize { @changed_files.add(file) }
      end

      def consume_changed_files
        @mutex.synchronize do
          pending = @changed_files.to_a
          @changed_files.clear
          pending
        end
      end

      def reload_file(file)
        load_quietly(file)
        $stdout.puts "[irb-reload] Reloaded #{file}"
      rescue LoadError
        # The file was removed or moved. Nothing to reload.
      rescue ScriptError, StandardError => e
        warn "[irb-reload] Failed to reload #{file}: #{e.class}: #{e.message}"
      end

      def load_quietly(file)
        old_verbose, $VERBOSE = $VERBOSE, nil
        Kernel.load(file)
      ensure
        $VERBOSE = old_verbose
      end
    end
  end
end

IRB::Command.register(:reload!, IRB::Reload::Command)
IRB::Reload.start
