module PuppetX
  module PuppetLabs
    module DscLite
      class PowerShellHashFormatter

        def self.format(dsc_value)
          case
          when dsc_value.class.name == 'String'
            self.format_string(dsc_value)
          when dsc_value.class.ancestors.include?(Numeric)
            self.format_number(dsc_value)
          when [:true, :false].include?(dsc_value)
            self.format_boolean(dsc_value)
          when ['trueclass','falseclass'].include?(dsc_value.class.name.downcase)
            "$#{dsc_value.to_s}"
          when dsc_value.class.name == 'Array'
            self.format_array(dsc_value)
          when dsc_value.class.name == 'Hash'
            self.format_hash(dsc_value)
          else
            fail "unsupported type #{dsc_value.class} of value '#{dsc_value}'"
          end

        end

        def self.format_string(value)
          "'#{escape_quotes(value)}'"
        end

        def self.format_number(value)
          "#{value}"
        end

        def self.format_boolean(value)
          "$#{value.to_s}"
        end

        def self.format_array(value)
          output = []
          output << "@("
          value.collect do |m|
            output << format(m)
          end
          output.join(', ')
          output << ")"
        end

        def self.format_hash(value)
          "@{\n" + value.collect{|k, v| format(k) + ' = ' + format(v)}.join(";\n") + "\n" + "}"
        end
        
        def self.escape_quotes(text)
          text.gsub("'", "''")
        end

      end
    end
  end
end
