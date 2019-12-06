#!/usr/bin/env ruby
# This script allows you to convert a Chef role to a JSON object.

require 'slop'
require 'chef'

def generate_json_file(role)
    role_obj = Chef::Role.new
    role_obj.from_file(role)
    json_file = Dir.pwd + '/' + File.basename(role, '.rb') + '.json'
    File.open(json_file, 'w'){|f| f.write(JSON.pretty_generate(role_obj))}
end

usage = %{
  Description: Convert one or more Chef roles from ruby to JSON format. 
               Json files are created in the current directory.
  Usage:       convert-chef-role [options] [path]
  Defaults:    convert-chef-role -h
}

opts = Slop.parse suppress_errors: true do |o|
    o.banner = usage

    o.string '-d', '--directory', 'Convert all roles from a given directory into a JSON object.', argument: :optional
    o.string '-f', '--file', 'Convert the specified role into a JSON object.', argument: :optional
    o.boolean '-h', '--help', 'Print this message and exit.', argument: :optional
end

if opts[:directory]
    ROLE_DIR = opts[:directory]
    if not File.directory?(ROLE_DIR)
        puts "Must enter a valid directory: " + ROLE_DIR
        exit 1
    end

    Dir.glob(File.join(ROLE_DIR, '*.rb')) do |role|
        generate_json_file(role)
    end

elsif role = opts[:file]
    if not File.file?(role)
        puts "Must enter a valid file: " + role
        exit 2
    end
    generate_json_file(role)
else
    puts opts
end
