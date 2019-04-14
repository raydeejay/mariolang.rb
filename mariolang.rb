#!/usr/bin/env ruby
# encoding: utf-8


if ARGV.length == 2 then
  s = File.new(ARGV[1], "r")
end
if ARGV.length == 1 then
  s = File.new(ARGV[0], "r")
end
if ARGV.length == 0 then
  exit 1
end


def elevdir(code, posx, posy)
  0.upto(code.length-1) { |i|
    if code[i].length >= posx then
      # elevator will always find a higher stop point
      return (if i < posy then -1 else 1 end) if code[i][posx] == "\""
    end
  }
  return 0
end

def moveto(x, y)
  print "\x1B[#{y+1};#{x+1}H"
end

def clear()
  print "\x1B[2J"
end


code = []
s.each { |line| code << line }
s.close()

vars = [0]
varl = varp = 0
posx = posy = 0
dirx = 1
diry = 0
elevator = false
skip = 0
output = ""
visual = (ARGV.length == 1)
delay = 0.01


clear() if visual

loop {
  if visual then
    moveto(0, 0)
    code.each do | line |
      print "\x1B[K" + line
    end
    moveto(posx, posy)
    print "\x1B[41;1mM\x1B[0m"
    moveto(0, code.length + 1)
    print "Output:\n"
    print output
    sleep(delay)
  end

  if posy < 0 then
    STDERR.print "Error: trying to get out of the program!\n"
    exit 1
  end

  if skip == 0 then
    case code[posy][posx]
    when "\""
      diry = -1
      elevator = false
    when ")"
      varp += 1
      vars << 0 if varp > vars.size - 1
    when "("
      varp -= 1
      if varp < 0 then
        STDERR.print "Error: trying to access Memory Cell -1\n"
        exit 1
      end
    when "+"
      vars[varp] += 1
    when "-"
      vars[varp] -= 1
    when "."
      print vars[varp].chr if not visual
      output << vars[varp].chr if visual
    when ":"
      print "#{vars[varp]} " if not visual
      output << "#{vars[varp]} " if visual
    when ","
      vars[varp] = STDIN.getc.ord
    when ";"
      vars[varp] = STDIN.gets.to_i
    when ">"
      dirx = 1
    when "<"
      dirx = -1
    when "^"
      diry = -1
    when "!"
      dirx = diry = 0
    when "["
      skip = 2 if vars[varp] == 0
    when "@"
      dirx = -dirx
    end
  end

  while code[posy][posx].nil?
    code[posy] << " "
  end

  exit 0 if posy == code.length - 1 or posx >= code[posy+1].length

  if "><@".include?(code[posy][posx]) and skip == 0 then
    elevator = false
    diry = 0
    posx += dirx
  elsif diry != 0 then
    skip -= 1 if skip > 0
    posy += diry
    diry = 0 if !elevator
  else
    case code[posy+1][posx]
    when "=", "|", "\""
      posx += dirx
    when "#"
      posx += dirx
      if dirx == 0 and code[posy][posx] == "!" and skip == 0 then
        elevator = true
        diry = elevdir(code, posx, posy)
        if diry == 0 then
          STDERR.print "Error: No matching elevator ending found!\n"
          exit 1
        end
        posy += diry
      end
    else
      posy += 1
    end
    skip -= 1 if skip > 0
  end
}
