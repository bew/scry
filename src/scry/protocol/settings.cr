require "json"

module Scry
  struct Settings
    # JSON.mapping({
    #   crystal_config: {type: Customizations, key: /^crystal.*/, default: Customizations.from_json("{}")},
    # })
    #
    # Here is the JSON.mapping manually expended with custom handling for the key

    @crystal_config : Customizations
    @actual_key : String?

    def crystal_config=(_crystal_config : Customizations)
      @crystal_config = _crystal_config
    end

    def crystal_config : Customizations
      @crystal_config
    end

    def initialize(json : ::JSON::PullParser)
      crystal_config_value = nil
      crystal_config_found = false
      actual_key = nil

      location = json.location
      begin
        json.read_begin_object
      rescue exc : ::JSON::ParseException
        raise ::JSON::MappingError.new(exc.message, self.class.to_s, nil, *location, exc)
      end
      while json.kind != :end_object
        key_location = json.location
        key = json.read_object_key
        case key
        when /^crystal.*/
          crystal_config_found = true
          actual_key = key
          begin
            crystal_config_value = json.read_null_or { Customizations.new(json) }
          rescue exc : ::JSON::ParseException
            raise ::JSON::MappingError.new(exc.message, self.class.to_s, "/^crystal.*/", *key_location, exc)
          end
        else
          json.skip
        end
      end
      json.read_next

      @crystal_config = crystal_config_value.nil? ? Customizations.from_json("{}") : crystal_config_value
      @actual_key = actual_key
    end

    def to_json(json : ::JSON::Builder)
      json.object do
        if (_crystal_config = @crystal_config) && (_actual_key = @actual_key)
          json.field(_actual_key) do
            _crystal_config.to_json(json)
          end
        end
      end
    end
  end

  struct Customizations
    JSON.mapping({
      max_number_of_problems: {type: Int32, key: "maxNumberOfProblems", default: 100},
      backend:                {type: String, default: "scry"},
      custom_command:         {type: String, key: "customCommand", default: "scry"},
      custom_command_args:    {type: Array(String), key: "customCommandArgs", default: [] of String},
      log_level:              {type: String, key: "logLevel", default: "info"},
    })
  end
end
