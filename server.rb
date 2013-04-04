#!/usr/bin/env ruby
require "socket"
require "cgi"

PORT = ARGV[1]
BASE_DIRECTORY = ARGV[3]
wpids = []
CONTENT_HEAD = "<html><head><title></title></head><body>"
CONTENT_FOOT = "</body></html>"
EXTENSION_MAPPINGS = {
                      :html => "text/html", 
                      :htm => "text/html",
                      :txt => "text/plain",
                      :css => "text/css",
                      :jpeg => "image/jpeg",
                      :jpg => "image/jpeg",
                      :gif => "image/gif",
                      :bmp => "image/bmp",
                      :png => "image/png",
                      :rb => "text/plain",
                      :xml => "text/xml",
                      :xsl => "text/xml",
                      }
DEFAULT_CONTENT_TYPE = "text/html"

def get_content_type(path)
    ext = File.extname(path).gsub('.', '')
    ext = ext.to_sym if ext.length > 0
    mapping = EXTENSION_MAPPINGS[ext]
    return mapping if mapping
    return DEFAULT_CONTENT_TYPE
end

def open_files(resource, session)
  buffer_size = 256
  File.open(resource, "rb") do |f|
    while (!f.eof?) do
      buffer = f.read(buffer_size)
      session.write(buffer)
    end
  end
end

def page_not_found(session)
  session.print "HTTP/1.1 404/Object Not Found\r\n\r\n"
  session.print "404 - Resource cannot be found."
  session.close
end

def hello_world(session)
  session.puts "Hello, World!"
  session.close
end

def get_resource_from_request(req)
  req.sub!(/\//, '')
  return "." if req.length == 0
  req
end

def print_form(session)
  session.print "HTTP/1.1 200/OK\r\nContent-type:text/html\r\n\r\n"
  session.close
end

def handle_query_strings(resource, session)
  parameters_array = []
  page, params = resource.split(/[?]/)
  parameters_array = params.split(/[=&]/)
  if parameters_array[1].include?('%')
    parameters_array[1] = CGI::unescape(parameters_array[1])
  end
  session.print "HTTP/1.1 200/OK\r\nContent-type:text/html\r\n\r\n"
  session.print(CONTENT_HEAD)
  puts 'Params' + parameters_array.inspect
  parameters_array.each_slice(2) do |x|
    session.print("<p>#{x.first + ' = ' + x[1]}</p>")
  end
  session.print(CONTENT_FOOT)
  session.close
end

def handle_404(session, resource)
  if resource == 'redirect'
    session.print "HTTP/1.1 307/Temporary Redirect\r\nLocation: http://localhost:#{PORT}/\r\n\r\n"
    session.close
  else
    page_not_found(session)
  end
end

def print_directory_listing(resource, session)
  session.print "HTTP/1.1 200/OK\r\nContent-type:text/html\r\n\r\n"
  session.print(CONTENT_HEAD)
  if resource == ""
    base_dir = Dir.new(".")
  else
    base_dir = Dir.new("./#{resource}")
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
end

def serve_file(contentType, resource, session)
  session.print "HTTP/1.1 200/OK\r\nContent-type: #{contentType}\r\n\r\n"
  open_files(resource, session)
end

Dir.chdir(BASE_DIRECTORY) unless BASE_DIRECTORY.nil?
webserver = TCPServer.new('localhost', PORT)
base_dir = Dir.new(".")
puts "Server is ready at port: #{PORT}\n"
5.times {
  wpids << fork do
    loop {

      session = webserver.accept
      request = session.gets

      if request.nil?
        next
      end

      puts "Directory: " + BASE_DIRECTORY unless BASE_DIRECTORY.nil?
      puts "Request: " + request

      request_method, trimmed_request = request.split(/\s/)
      resource = get_resource_from_request(trimmed_request)

      if BASE_DIRECTORY.nil?
        hello_world(session)
        next
      end

      if resource == 'favicon.ico'
        next
      end

      puts 'Resource: ' + resource
      if resource.include?('?')
        handle_query_strings(resource, session)
        next
      end

      if resource == 'form'
        print_form(session)
        next
      end

      if !File.exists?(resource)
        handle_404(session, resource)
        next
      end

      if File.directory?(resource)
        print_directory_listing(resource, session)
      else
        contentType = get_content_type(resource)
        serve_file(contentType, resource, session)
      end

      session.print(CONTENT_FOOT) if contentType == DEFAULT_CONTENT_TYPE
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

