# frozen_string_literal: true

require "irb"
require "listen"

require_relative "reload/version"
require_relative "reload/command"

module IRB
  module Reload
    DEFAULT_PATTERN = /\.rb\z/.freeze
    DEFAULT_PATHS = ["lib"]

    class << self
      def start
        @changed_files = Set.new
        normalized_paths = normalize_paths(config[:paths] || DEFAULT_PATHS)
        listener_options = default_listen_option

        @listener = Listen.to(*normalized_paths, **listener_options) do |modified, added, _removed|
          record_changed_files(modified, added)
        end

        @listener.start
        true
      end

      def reload!
        @changed_files.each do |file|
          reload_file(file)
        end
        @changed_files.clear
      end

      def watched_paths
        return [] unless @listener

        @listener.respond_to?(:directories) ? @listener.directories : []
      end

      def config
        IRB.conf[:RELOAD] ||= {}
      end

      private

      def default_listen_option
        options = { only: DEFAULT_PATTERN }
        config_options = config.fetch(:listen, {})
        options.merge!(symbolize_keys(config_options))
        options
      end

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

      def symbolize_keys(hash)
        hash.each_with_object({}) do |(key, value), memo|
          memo[key.to_sym] = value
        end
      end
    end
  end
end

IRB::Command.register(:reload!, IRB::Reload::Command)
IRB::Reload.start
