# Monkeypatch String to include #rewind so we can handle broken handling of
# uploads with content-type params.
class String
  def rewind
  end
end
