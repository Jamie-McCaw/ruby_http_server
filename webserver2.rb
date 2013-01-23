require 'socket'
require 'pry'

port = ARGV.shift
dir = File.expand_path(ARGV.shift)
work_dir = []

def get_content_type(path)
    ext = File.extname(path)
    return "text/html"  if ext == ".html" or ext == ".htm"
    return "image/png"  if ext == ".png"
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


server = TCPServer.open(port)
puts "Server is ready at port: #{port}\n" 
loop {                          
  Thread.start(server.accept) do |session|
    request = session.gets
    trimmed_request = request.gsub(/GET\ \//, '').gsub(/\ HTTP.*/, '').chomp
    resource = trimmed_request
    if dir.nil?
      session.puts 'Hello, World!'
      session.close
      next
    end
    if resource == 'favicon.ico'
    next
    end
    if resource == ""
       resource = dir
    end
  
    puts "Resource: " + resource
    if !File.exists?(resource)
      session.print "HTTP/1.1 404/Object Not Found\r\n\r\n"
      session.print "404 - Resource cannot be found."
      session.close
      next
    end
    if File.directory?(resource)
        #Dir.chdir("#{resource}") 
        puts "Request: "     + request
        puts "Resource: "    + resource
        puts "Current Dir: " + Dir.pwd
        puts "Base dir: "    + dir
        puts "====================\n"
    
        session.print "HTTP/1.1 200/OK\r\nContent-type:text/html\r\n\r\n"
        session.puts Dir.entries(resource).map { |file|
          if File.directory?(file)
            "<a href='#{File.expand_path(file).gsub(dir,"")}'/>#{file}/</a>" 
          else
            "<a href='#{File.expand_path(file).gsub(dir,"")}'>#{file}</a>"
          end
          }.join("<br />")
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