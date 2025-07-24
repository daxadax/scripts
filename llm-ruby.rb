require "pathname"
require "optparse"
require "open3"

module LlmRuby
  class CLI
    MODEL = 'gpt-4o-mini'

    def self.run(argv)
      options = {
        model: MODEL,
        ruleset: "#{ENV['HOME']}/programming/ai-rulesets/ruby-code.md"
      }

      opt = OptionParser.new do |opts|
        opts.banner = "Usage: llm_ruby <query> <files/dirs> [options]"

        opts.on("--ruleset FILE", "Path to ruleset markdown") { |r| options[:ruleset] = r }
        opts.on("--model MODEL", "LLM model to use (default: #{MODEL})") { |m| options[:model] = m }
        opts.on("--code", "Only return code output") { options[:code_only] = true }
      end

      opt.parse!(argv)

      query = argv.shift
      paths = argv.map { |p| Pathname(p).expand_path }

      if query.nil?
        puts opt.help
        exit 1
      end

      files = paths.flat_map do |path|
        if path.directory?
          Dir[path.join("**", "*.{rb,rake}")].map { |f| Pathname(f) }
        elsif path.file?
          [path]
        else
          []
        end
      end

      rules_text = File.read(File.expand_path(options[:ruleset]))

      prompt = +"## Ruleset\n\n#{rules_text}\n\n"
      prompt << "## Task\n\n#{query}\n\n"

      if files.any?
        prompt << "## Files\n"

        files.each do |file|
          content = File.read(file)
          prompt << "\n### #{file}\n```ruby\n#{content}\n```\n"
        end
      end

      llm_args = ["llm", "--model", options[:model]]
      llm_args << "--code" if options[:code_only]

      Open3.popen3(*llm_args) do |stdin, stdout, stderr, wait_thr|
        stdin.write(prompt)
        stdin.close

        puts stdout.read
        warn stderr.read
        exit wait_thr.value.exitstatus
      end
    end
  end
end

LlmRuby::CLI.run(ARGV)
