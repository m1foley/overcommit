module Overcommit
  module GitHook
    class BaseHook
      include ConsoleMethods

      def initialize
        Overcommit.config.desired_plugins.each do |plugin|
          require plugin
        end
      rescue NameError => ex
        error "Couldn't load plugin: #{ex}"
        exit 0
      end

      def run(*args)
        # Support 'bare' installation where we don't have any hooks yet.
        # Silently pass.
        exit unless (checks = HookRegistry.checks) && checks.any?

        exit if requires_modified_files? && Utils.modified_files.empty?

        reporter = Reporter.new(Overcommit::Utils.hook_name, checks)

        reporter.print_header

        checks.each do |check_class|
          check = check_class.new(*args)
          next if check.skip?

          # Ignore a check if it only applies to a specific file type and there
          # are no staged files of that type in the tree
          next if check_class.filetype && check.staged.empty?

          reporter.with_status(check) do
            check.run_check
          end
        end

        reporter.print_result
      end

    private

      # If true, only run this check when there are modified files.
      def requires_modified_files?
        false
      end
    end
  end
end