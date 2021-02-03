#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'

def get_card_info
  info = `pactl list cards`
  parse_tabbed_info(info.split("\n"))
end

def get_blues_card
  card_info = get_card_info()

  card = card_info.find { |c| c[1]["Properties"]["device.bus"] == "bluetooth" }

  if card != nil
    card[1]
  end
end

def get_client_info
  info = `pactl list clients`
  parse_tabbed_info(info.split("\n"))
end

def get_sink_input_info
  info = `pactl list sink-inputs`
  parse_tabbed_info(info.split("\n"))
end

def count_indent(str)
  str.chars.count { |char| char == "\t" }
end

def switch
  card = get_blues_card()

  if card != nil
    if not system("pactl set-card-profile #{card["Name"]} headset_head_unit")
      raise "Cannot set card profile. Non zero exit code!"
    end
  else
    puts "Bluetooth sink not found!"
    sleep 1
    return
  end

  while true
    sinks = get_sink_input_info()
    sink = sinks.find { |s| @config["validClients"].include?(s[1]["Properties"]["application.name"]) } 
    if sink == nil
      puts "Sink use finished! Switching back..."
      break
    end
    puts "Sink in use: #{sink[1]["Properties"]["application.name"]}"
    sleep 1
  end

  system("pactl set-card-profile #{card["Name"]} a2dp_sink")
end

def parse_tabbed_info(lines)
  if lines.length == 0
    return {}
  end

  i = 0
  init_indent = count_indent(lines[0])
  out = {}

  while i < lines.length
    if lines[i].include?("=")
      splitted = lines[i].split("=")
      key = splitted[0].strip()
      value = splitted.drop(1).join("=").strip()

      if value.start_with?("\"") and value.end_with?("\"")
        value = value[1..-2]
      end

      out[key] = value
    elsif lines[i].include?(":") and not lines[i].strip.end_with?(":")
      splitted = lines[i].split(":")
      key = splitted[0].strip()
      value = splitted.drop(1).join(":").strip()

      out[key] = value
    elsif lines[i].strip() != ""
      in_indent = select_in_indent(lines, i)
      num = lines[i].strip.end_with?(":") ? -2 : -1
      out[lines[i][0..num].strip()] = parse_tabbed_info(in_indent)
      i += in_indent.length
    end

    i += 1
  end

  out || {}
end

def select_in_indent(lines, start)
  start_indent = count_indent(lines[start])

  end_at = start + 1

  while end_at < lines.length
    indents = count_indent(lines[end_at])

    if indents <= start_indent
        break
    end

    end_at += 1
  end

  return lines[start + 1, end_at - start - 1]
end


def should_switch(client)
  if client != nil and client["Properties"] != nil
    app_name = client["Properties"]["application.name"]
    puts "Checking request by #{app_name}"
    @config["validClients"].include?(app_name)
  else
    false
  end
end

def subscribe_to_pa
  f = IO.popen("pactl subscribe")
  
  puts "Listening for sink-input requests..."
  
  while true
    line = f.readline
  
    if line.include?("sink-input")
      client_name = line[line.index("#")..-1].strip
      client = get_sink_input_info()["Sink Input #{client_name}"]
      if should_switch(client)
        puts "Sink requested by #{client["Properties"]["application.name"]}!"
        Process.kill(9, f.pid)
        switch()
        f = IO.popen("pactl subscribe")
      end
    end
  end
end

@config_files = ["config.yaml", "~/.config/bluez_pa_auto_switcher/config.yaml", "/etc/bluez_pa_auto_switcher/config.yaml"]

def load_config
  for file in @config_files
    if File.exist?(file)
      return YAML.load_file(file)
    end
  end

  puts "No config files detected... Using defaults!"

  return {"validClients" =>  ["Firefox", "Chromium", "Skype", "ZOOM VoiceEngine", "WEBRTC VoiceEngine", "Google Chrome", "Microsoft Teams - Preview"]}
end

@config = load_config()

while true
  subscribe_to_pa()
end
