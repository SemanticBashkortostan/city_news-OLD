def template(from, to, locals = {})
  erb = File.read(File.expand_path("../../templates/#{from}", __FILE__))
  upload! StringIO.new(ERB.new(erb).result(binding)), to
end

def set_default(key, default_value)
  set key, fetch(key, default_value)
end

def init_script(path, name)
  template "#{path}", "/tmp/#{name}"
  sudo :cp, "-f", "/tmp/#{name}", "/etc/init.d/#{name}"
  sudo :chmod, "755", "/etc/init.d/#{name}"
end