#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



# Use data after __END__ in .rb files like normal files
#
# WARNING:
# - if you have an __END__ alone in a multiline comment or string
#   your .rb file will be damaged.
# - Current implementation *will* append an __END__ to the file, regardeless
#   of what you do (that will change)
#
# Example:
#   require 'scriptfile'
#   ScriptFile.open(__FILE__) { |fh|
#     p [:tell, fh.tell]
#     p [:read, fh.read]
#     p [:tell, fh.tell]
#     p [:truncate, fh.truncate]
#     p [:tell, fh.tell]
#     p [:read, fh.read]
#     p [:tell, fh.tell]
#     p [:seek, fh.seek]
#     p [:puts, fh.puts("ScriptFile rocks")]
#     p [:seek, fh.seek]
#     p [:read, fh.read]
#   }
#
class ScriptFile < File
  (IO.instance_methods(false)+File.instance_methods(false) - %w[see tell pos truncate]).each { |m| private m }

  class <<self
    def read(file)
      open(file) { |fh| fh.read }
    end
  
    def open(file, mode="r")
      fh = new(file, mode)
      block_given? ? yield(fh) : fh
    ensure
      fh.close if fh and block_given?
    end
  end
    
  def initialize(file, mode="r")
    super(file, "r+") # "r#{'+' unless mode=='r'}"
    @offset = 0
    while line = gets
      @offset += line.size
      break if line =~ /^__END__$/
    end
    unless line then
      file_seek(-1, IO::SEEK_CUR)
      unless read(1) == "\n" then
        puts
        @offset += 1
      end
      print "__END__\n"
      @offset += 8
    end
    case mode
      when /^w/: truncate
      when /^a/: read
    end
  end

  public :each, :each_byte, :each_line
  public :gets, :getc, :read, :readchar, :readline, :readlines
  public :puts, :putc, :print, :printf, :write
  public :ctime, :atime, :mtime
  
  alias file_seek seek unless method_defined?(:file_seek)
  private :file_seek
  
  def seek(offset=0, type=IO::SEEK_SET)
    raise ArgumentError, "negative seeks currently not supported" if offset < 0
    raise ArgumentError, "no type but IO::SEEK_SET supported at the moment" if type != IO::SEEK_SET
    super(offset+@offset)
  end

  def truncate(bytes=0)
    super(bytes+@offset)
    seek(bytes)
    0
  end
  
  def tell
    super-@offset
  end

  def pos
    super-@offset
  end

  public :close
end