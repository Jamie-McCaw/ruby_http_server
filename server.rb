#!/usr/bin/env ruby
require "socket"
require "cgi"


port = ARGV[1]
directory = ARGV[3]
wpids = []
content_head = "<html><head><title></title></head><body>"
content_foot = "</body></html>"
 
def get_content_type(path)
    ext = File.extname(path)
    return "text/html"  if ext == ".html" or ext == ".htm"
    return "text/plain" if ext == ".txt"
    return "text/css"   if ext == ".css"
    return "image/jpeg" if ext == ".jpeg" or ext == ".jpg"
    return "image/gif"  if ext == ".gif"
    return "image/bmp"  if ext == ".bmp"
    return "image/png"  if ext == ".png"
    return "text/plain" if ext == ".rb"
    return "text/xml"   if ext == ".xml"
    return "text/xml"   if ext == ".xsl"
    return "text/html"
end

def open_files(resource, session)
  File.open(resource, "rb") do |f|
    while (!f.eof?) do
      buffer = f.read(256)
      session.write(buffer)
    end
  end
end

def page_not_found(session)
  session.print "HTTP/1.1 404/Object Not Found\r\n\r\n"
  session.print "404 - Resource cannot be found."
  session.close
end

Dir.chdir(directory) unless directory.nil? 
webserver = TCPServer.new('localhost', port)
base_dir = Dir.new(".")
puts "Server is ready at port: #{port}\n" 
5.times {
  wpids << fork do
    loop { 
      session = webserver.accept
      request = session.gets
      if request.nil?
        next
      end
      puts "Directory: " + directory unless directory.nil?
      puts "Request: " + request
      request_method, trimmed_request = request.split(/\s/)
      resource =  trimmed_request.sub(/\//, '')
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
      if resource.include?('?')
        parameters_array = []
        page, params = resource.split(/[?]/)
        parameters_array = params.split(/[=&]/)       
        if parameters_array[1].include?('%')
          parameters_array[1] = CGI::unescape(parameters_array[1])
        end
        session.print "HTTP/1.1 200/OK\r\nContent-type:text/html\r\n\r\n"
        session.print(content_head)
        puts 'Params' + parameters_array.inspect
        parameters_array.each_slice(2) do |x|
          session.print("<p>#{x.first + ' = ' + x[1]}</p>")
        end
        session.print(content_foot)
        session.close
        next
      end
      if resource == 'form'
        session.print "HTTP/1.1 200/OK\r\nContent-type:text/html\r\n\r\n"
        session.close
        next
      end

      if !File.exists?(resource)
        if resource == 'redirect'
          session.print "HTTP/1.1 307/Temporary Redirect\r\nLocation: http://localhost:#{port}/\r\n\r\n"
          session.close
        else
          page_not_found(session)
        end
        next
      end 
      if File.directory?(resource)
        session.print "HTTP/1.1 200/OK\r\nContent-type:text/html\r\n\r\n"
        session.print(content_head)
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
        open_files(resource, session)
      end
      session.print(content_foot) unless contentType == "text/plain"
      session.close
    }
  end
}
Process.waitall
[:INT, :QUIT].each do |signal|
  Signal.trap(signal) {
    wpids.each { |wpid| Process.kil(signal, wpid) }
  }
end

