# 
# This is a real plugin updated to use our newer interface:
# 
#   http://scoutapp.com/plugin_urls/static/creating_a_plugin
# 
class LoadAverages < ScoutAgent::Plugin
  TEST_USAGE = "#{File.basename($0)} max_load MAX_LOAD"

   def build_report
     if `uptime` =~ /load average(s*): ([\d.]+)(,*) ([\d.]+)(,*) ([\d.]+)\Z/
       report :last_minute          => $2,
              :last_five_minutes    => $4,
              :last_fifteen_minutes => $6
     else
       raise "Unexpected output format"  
     end
     if option(:max_load) and
        reports.last[:last_minute].to_f > option(:max_load).to_f
       alert "Maximum Load Exceeded (#{reports.last[:last_minute]})", ""
     end
  rescue Exception
    error "Couldn't use `uptime` as expected.", $!.message
  end
end