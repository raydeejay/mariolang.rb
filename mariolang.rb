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

code = s.collect { |line| line }
s.close()

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

def colorForChar(c)
  {
    "=" => "33",
    "-" => "31",
    "+" => "32",
    # "<" => "37;1",
    # ">" => "37;1",
    "(" => "33;1",
    ")" => "33;1",
    "#" => "31;1",
    "\"" => "36;1",
    "[" => "35;1",
  }[c] or "0"
end

def printCode(code, x, y)
  moveto(x, y)
  print "\x1B[0m "
  moveto(x, y)
  print "\x1B[#{colorForChar(code[y][x])}m#{code[y][x]}\x1B[0m"
end

def printMario(x, y)
  moveto(x, y)
  print "\x1B[41;1mM\x1B[0m"
end

def printLevel(code)
  clear()
  moveto(0, 0)
  code.each.with_index do | line, y |
    moveto(0, y)
    print "\x1B[K"
    line.split('').each.with_index do | char, x |
      printCode(code, x, y)
    end
  end
  moveto(0, code.length + 1)
  print "Output:\n"
end

vars = [0]
varl = varp = 0
posx = posy = 0
oldx = oldy = 0
dirx = 1
diry = 0
elevator = false
skip = 0
output = ""
outputCount = 4
visual = (ARGV.length == 1)
delay = 0.02
prefix = 0


if visual then
  printLevel(code)
end

loop {
  if visual then
    printCode(code, oldx, oldy)
    printMario(posx, posy)
    moveto(0, code.length + 2)
    u = output.split("\n").last(outputCount).join("\n")
    print "\x1B[0J#{u}"
    sleep(delay)
  end

  oldx = posx
  oldy = posy
  
  if posy < 0 then
    STDERR.print "Error: trying to get out of the program!\n"
    exit 1
  end

  if skip == 0 then
    case code[posy][posx]
    when ("0".."9")
      prefix = prefix * 10 + code[posy][posx].to_i
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
      if prefix == 0 then
        vars[varp] = (vars[varp] + 1) % 256
      else
        vars[varp] = (vars[varp] + prefix) % 256
      end
      prefix = 0
    when "-"
      if prefix == 0 then
        vars[varp] = (vars[varp] - 1) % 256
      else
        vars[varp] = (vars[varp] - prefix) % 256
      end
      prefix = 0
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
