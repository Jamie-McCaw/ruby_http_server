require "socket"
require "pry"

port = ARGV.shift
directory = ARGV.shift
 
def get_content_type(path)
    ext = File.extname(path)
    return "text/html"  if ext == ".html" or ext == ".htm"
    return "text/png"   if ext == ".png"
    return "text/plain" if ext == ".txt"
    return "text/css"   if ext == ".css"
    return "image/jpeg" if ext == ".jpeg" or ext == ".jpg"
    return "image/gif"  if ext == ".gif"
    return "image/bmp"  if ext == ".bmp"
    return "text/plain" if ext == ".rb"
    return "text/xml"   if ext == ".xml"
    return "text/xml"   if ext == ".xsl"
    return "text/html"
end
 
webserver = TCPServer.new('localhost', port)
base_dir = Dir.new(".")
puts "Server is ready at port: #{port}\n" 
loop {
  Thread.start(webserver.accept) do |session|
    request = session.gets
    puts "Request: " + request
    trimmed_request = request.gsub(/GET\ \//, '').gsub(/\ HTTP.*/, '').chomp
    resource =  trimmed_request
    if directory.nil?
      session.puts "Hello, World!"
      session.close
      next
    end
    if resource == 'favicon.ico'
      next
    end
    if resource == ""
      resource = "."
    end
    puts 'Resource: ' + resource
   
    if !File.exists?(resource)
      session.print "HTTP/1.1 404/Object Not Found\r\n\r\n"
      session.print "404 - Resource cannot be found."
      session.close
      next
    end
    if File.directory?(resource)
      session.print "HTTP/1.1 200/OK\r\nContent-type:text/html\r\n\r\n"
      if resource == ""
        base_dir = Dir.new(".")
      else
        base_dir = Dir.new("./#{trimmed_request}")
      end
      base_dir.entries.each do |file|
        dir_sign = ""
        base_path = resource + "/"
        base_path = "" if resource == ""
        resource_path = base_path + file
        if File.directory?(resource_path)
          dir_sign = "/"
        end
        if file == ".."
          upper_dir = base_path.split("/")[0..-2].join("/")
          session.print("<a href='/#{upper_dir}'>#{file}/</a><br />")
        else
          puts resource_path
          session.print("<a href='/#{resource_path}'>#{file}#{dir_sign}</a><br />")
        end
      end
    else
      contentType = get_content_type(resource)
      session.print "HTTP/1.1 200/OK\r\nContent-type: #{contentType}\r\n\r\n"
      File.open(resource, "rb") do |f|
        while (!f.eof?) do
          buffer = f.read(256)
          session.write(buffer)
        end
      end
    end
    session.close
  end
}
