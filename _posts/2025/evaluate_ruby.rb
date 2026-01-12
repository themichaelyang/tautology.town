#!/usr/bin/env ruby

require 'open3'

# Parse markdown file and execute Ruby code blocks
class RubyMarkdownEvaluator
  def initialize(file_path)
    @file_path = file_path
    @content = File.read(file_path)
  end

  def process!
    new_content = []
    in_ruby_block = false
    current_block_lines = []
    
    @content.lines.each do |line|
      if line.strip == '```ruby'
        in_ruby_block = true
        new_content << line
      elsif line.strip == '```' && in_ruby_block
        in_ruby_block = false
        # Process the accumulated block
        processed_block = process_ruby_block(current_block_lines)
        new_content.concat(processed_block)
        new_content << line
        current_block_lines = []
      elsif in_ruby_block
        current_block_lines << line
      else
        new_content << line
      end
    end
    
    File.write(@file_path, new_content.join)
    puts "Updated #{@file_path}"
  end
  
  private
  
  def process_ruby_block(lines)
    # Check if this block has any IRB prompts
    has_irb = lines.any? { |line| line.strip =~ /^irb\([^)]+\):\d+[>*]/ }
    
    # If no IRB prompts, return the lines unchanged
    return lines unless has_irb
    
    result = []
    accumulated_code = []
    accumulated_lines = []
    
    # Collect all code to execute for this block
    code_snippets = []
    
    lines.each do |line|
      stripped = line.strip
      
      # Check if this is an IRB input line
      if stripped =~ /^irb\([^)]+\):(\d+)([>*])\s*(.*)$/
        line_num = $1
        prompt_char = $2  # '>' for new statement, '*' for continuation
        code = $3
        
        # Keep the original line with the prompt
        accumulated_lines << line
        accumulated_code << code
        
        # If this is a continuation line (marked with *), keep accumulating
        if prompt_char == '*'
          next
        end
        
        # This is the end of a statement (marked with >), save it
        full_code = accumulated_code.join("\n")
        code_snippets << { lines: accumulated_lines.dup, code: full_code }
        
        # Reset accumulation
        accumulated_code = []
        accumulated_lines = []
      end
    end
    
    # Execute all code snippets in a single subprocess to maintain state
    outputs = execute_code_block(code_snippets)
    
    # Build result with input lines and outputs
    code_snippets.each_with_index do |snippet, idx|
      result.concat(snippet[:lines])
      result << "#{outputs[idx]}\n" if outputs[idx]
    end
    
    # Remove trailing blank lines from the result
    while result.last && result.last.strip.empty?
      result.pop
    end
    
    result
  end
  
  def execute_code_block(code_snippets)
    # Create a Ruby script that executes all code sequentially and outputs results
    # We execute code at top level and capture last expression value using eval
    script_lines = ["__binding = binding"]
    
    code_snippets.each_with_index do |snippet, idx|
      script_lines << <<~RUBY
        begin
          __result_#{idx} = __binding.eval(#{snippet[:code].inspect})
          puts "___RESULT_#{idx}___"
          puts __result_#{idx}.inspect
        rescue => e
          puts "___ERROR_#{idx}___"
          puts "\#{e.message} (\#{e.class})"
        end
      RUBY
    end
    
    script = script_lines.join("\n")
    
    # Execute in subprocess
    stdout, stderr, status = Open3.capture3('ruby', '-e', script)
    
    # Parse outputs and match them to code snippets
    outputs = {}
    current_idx = nil
    current_output = []
    
    stdout.each_line do |line|
      line = line.chomp
      if line =~ /^___RESULT_(\d+)___$/
        # Save previous output if any
        if current_idx
          outputs[current_idx] = current_output.join
          current_output = []
        end
        current_idx = $1.to_i
        current_output << "=> "
      elsif line =~ /^___ERROR_(\d+)___$/
        # Save previous output if any
        if current_idx
          outputs[current_idx] = current_output.join
          current_output = []
        end
        current_idx = $1.to_i
      elsif current_idx
        current_output << line
      end
    end
    
    # Save last output
    if current_idx
      outputs[current_idx] = current_output.join
    end
    
    outputs
  end
end

# Main execution
if ARGV.empty?
  puts "Usage: ruby evaluate_ruby.rb <markdown_file>"
  exit 1
end

evaluator = RubyMarkdownEvaluator.new(ARGV[0])
evaluator.process!
