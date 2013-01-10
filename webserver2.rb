#!/usr/bin/ruby
require "socket"
require "pry"

port = ARGV.shift
dir = ARGV.shift
 
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
 
webserver = TCPServer.new port
while (session = webserver.accept)
  request = session.gets
  continue if request.nil?
  trimmedrequest = request.gsub(/GET\ \//, '').gsub(/\ HTTP.*/, '').chomp
  resource =  trimmedrequest
  if dir.nil?
    session.puts 'Hello, World!'
    session.close
    dir = '.'
    next
  end
  if resource == 'favicon.ico'
    next
  end
  if resource == ""
    resource = "."
  end
 
  if !File.exists?(resource)
    session.print "HTTP/1.1 404/Object Not Found\r\n\r\n"
    session.print "404 - Resource cannot be found."
    session.close
    next
  end
 
  if File.directory?(resource)
    session.print "HTTP/1.1 200/OK\r\nContent-type:text/html\r\n\r\n"
    Dir.chdir("#{resource}")
    session.puts Dir.entries("#{dir}").map { |file| "<a href='#{dir}/#{file}'>#{file}</a>"}.join("<br />")
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
