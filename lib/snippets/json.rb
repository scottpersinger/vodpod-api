class Exception
  case API.config.mode
  when :dev
    def as_json
      { 
        'message' => to_s,
        'backtrace' => self.backtrace.join("\n")
      }
    end
  else
    def as_json
      {
       'message' => 'server error'
      }
    end
  end

  def to_json(*a)
    as_json.to_json *a
  end
end
