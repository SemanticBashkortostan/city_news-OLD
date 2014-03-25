def template(from, to, locals = {})
  erb = File.read(File.expand_path("../../templates/#{from}", __FILE__))
  upload! StringIO.new(ERB.new(erb).result(binding)), to
end

def monit_config(path, name)
  template "#{path}", "/tmp/#{name}"
  sudo :cp, "-f", "/tmp/#{name}", "/etc/monit/conf.d/#{name}"
  sudo :chmod, "644", "/etc/monit/conf.d/#{name}"
end

def init_script(path, name)
  template "#{path}", "/tmp/#{name}"
  sudo :cp, "-f", "/tmp/#{name}", "/etc/init.d/#{name}"
  sudo :chmod, "755", "/etc/init.d/#{name}"
end

def set_default(key, default_value)
  set key, fetch(key, default_value)
end