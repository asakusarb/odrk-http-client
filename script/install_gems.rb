CLIENTS = File.expand_path('../clients.txt', File.dirname(__FILE__))

require 'csv'

require 'rbconfig'
# We have RbConfig.ruby from 1.9
ruby = File.join(RbConfig::CONFIG["bindir"], RbConfig::CONFIG["ruby_install_name"] + RbConfig::CONFIG["EXEEXT"])

CSV.parse(File.read(CLIENTS)) do |row|
  name, gem, one_nine, repo = row.map { |e| e.strip }
  next if RUBY_VERSION >= "1.9" and one_nine == 'no'
  if gem == 'yes'
    p name
    #system "#{ruby} -S gem install #{name} --user-install --no-ri --no-rdoc"
  end
end
