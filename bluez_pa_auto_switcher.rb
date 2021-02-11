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

def has_bluetooth_sink?(card = nil)
  get_blues_card() != nil
end

def switch(client_id)
  card = get_blues_card()

  if card != nil
    if not system("pactl set-card-profile #{card["Name"]} #{@config["inputCardProfile"] || "headset_head_unit"}")
      raise "Cannot set card profile. Non zero exit code!"
    end
  else
    puts "Bluetooth sink not found!"
    sleep 1
    return
  end

  sleep(2)

  while true
    sinks = get_sink_input_info()
    sink = sinks.find { |s| s[0].end_with?(client_id) } 
    if sink == nil
      puts "Sink use finished! Switching back..."
      break
    end
    puts "Sink in use: #{sink[0]} (#{sink[1]["Properties"]["application.name"]})"
    sleep 1
  end

  `zenity --notification --text="Switching profile of bluetooth headset back to A2DP."`
  system("pactl set-card-profile #{card["Name"]} #{@config["normalCardProfile"] || "a2dp_sink"}")
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
  if not has_bluetooth_sink?()
    puts "Bluetooth sink not found"
    return false
  end

  if client != nil and client["Properties"] != nil
    app_name = client["Properties"]["application.name"]
    puts "Checking request by #{app_name}"
    if (@config["invalidClients"] || {}).include?(app_name)
      puts "#{app_name} is in invalidClients blacklist"
      return false
    else
      res = `zenity --title="Bluetooth headset mic requested" --list --column="Action ID" --column="Choose action" "1" "Switch to HSP/HFP" "2" "Not this time" "3" "Never for #{app_name}" --hide-column=1`
      res = res.strip

      case res
      when "1"
        puts "Request accepted #{app_name}"
        return true
      when "2"
        puts "Request rejected just this time #{app_name}"
        sleep(3)
        return false
      when "3"
        puts "#{app_name} Blacklist request"
        add_invalid_client(app_name)
        return false
      end
    end

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
      client_id = line[line.index("#")..-1].strip
      client = get_sink_input_info()["Sink Input #{client_id}"]
      if should_switch(client)
        puts "Sink requested by #{client["Properties"]["application.name"]}!"
        Process.kill(9, f.pid)
        switch(client_id)
        f = IO.popen("pactl subscribe")
      end
    end
  end
end

@config_files = ["config.yaml", "~/.config/bluez_pa_auto_switcher/config.yaml", "/etc/bluez_pa_auto_switcher/config.yaml"]

def get_config_file
  for file in @config_files
    if File.exist?(file)
      return file
    end
  end

  return nil

end

def load_config
  file = get_config_file()
  if file != nil
    puts "Loading config from #{file}"
    return YAML.load_file(file)
  else
    puts "No config files detected... Using defaults!"

    return {"invalidClients" =>  []}
  end
end

def add_invalid_client(client_name)
  if not @config["invalidClients"].include?("client_name")
    @config["invalidClients"].append(client_name) 
    dst_config = get_config_file() || "config.yaml" 
    File.open(dst_config, "w") {|f| f.write @config.to_yaml }
    puts "Wrote new config to #{dst_config}"
  else
    puts "#{client_name} already included"
  end
end

@config = load_config()

while true
  begin
    subscribe_to_pa()
  rescue => e
    puts "Error #{e}"
  end
  sleep 5
end
