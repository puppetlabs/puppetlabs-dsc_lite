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
          when dsc_value.class.name == 'Puppet::Pops::Types::PSensitiveType::Sensitive'
            "'#{escape_quotes(dsc_value.unwrap)}' <# PuppetSensitive #>"
          else
            fail "unsupported type #{dsc_value.class} of value '#{dsc_value}'"
          end
        end

        private
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
          "@(" + value.collect{|m| format(m) }.join(', ') + ")"
        end

        def self.format_hash(value)
          if !value.has_key?('dsc_type')
            format_hash_to_string(value)
          else
            case value['dsc_type']
            when 'MSFT_Credential'
              "([PSCustomObject]#{format_hash(value['dsc_properties'])} | new-pscredential)"
            else
              format_ciminstance(value)
            end
          end
        end

        def self.format_hash_to_string(value)
          "@{\n" + value.collect{|k, v| format(k) + ' = ' + format(v)}.join(";\n") + "\n" + "}"
        end

        def self.format_ciminstance(value)
          type       = value['dsc_type'].gsub('[]','')
          properties = [value['dsc_properties']].flatten

          output = properties.map do |p|
            "(New-CimInstance -ClassName '#{type}' -ClientOnly -Property #{format_hash_to_string(p)})"
          end

          if value['dsc_type'].end_with?('[]')
            output = output.join(",\n")
            "[CimInstance[]]@(\n" + output +  "\n)"
          else
            "[CimInstance]#{output.first}"
          end

        end

        def self.escape_quotes(text)
          text.gsub("'", "''")
        end

      end
    end
  end
end
