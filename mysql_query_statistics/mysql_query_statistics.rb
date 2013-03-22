# MySQL Statistics by Eric Lindvall <eric@5stops.com>
# MySQLTuner integration by Andre Lewis <@andre@scoutapp.com>
class MysqlQueryStatistics < Scout::Plugin
  ENTRIES = %w(Com_insert Com_select Com_update Com_delete)

  OPTIONS=<<-EOS
  user:
    name: MySQL username
    notes: Specify the username to connect with
    default: root
  password:
    name: MySQL password
    notes: Specify the password to connect with
    attributes: password
  host:
    name: MySQL host
    notes: Specify something other than 'localhost' to connect via TCP
    default: localhost
  port:
    name: MySQL port
    notes: Specify the port to connect to MySQL with (if nonstandard)
  socket:
    name: MySQL socket
    notes: Specify the location of the MySQL socket
  EOS

  # Raised by #mysql_query when an error occurs.
  class MysqlConnectionError < Exception
  end

  def build_report
    mysql_status = mysql_query('SHOW /*!50002 GLOBAL */ STATUS')

    report(:max_used_connections => mysql_status['Max_used_connections'])
    report(:connections => mysql_status['Threads_connected'])

    total = 0
    mysql_status.each do |k,v|
      if ENTRIES.include?(k)
        total += v
        counter(k[/_(.*)$/, 1], v, :per => :second)
      end
    end
    counter(:total, total, :per => :second)
        
  rescue MysqlConnectionError => e
    error("Unable to connect to MySQL",e.message)
  end

  private

  # Returns nil if an empty string
  def get_option(opt_name)
    val = option(opt_name)
    return (val.is_a?(String) and val.strip == '') ? nil : val
  end
  
  # Executes a mysql query via the 'mysql' command. Returns a Hash of variable names and their values.
  def mysql_query(query)
    result = `mysql #{connection_options} -e '#{query}' --batch 2>&1`
    if $?.success?
      output = {}
      result.split(/\n/).each do |line|
        row = line.split(/\t/)
        output[row.first] = row.last.to_i
      end
      output
    else
      raise MysqlConnectionError, result
    end
  end
  
  # Returns a string of connection options for the mysql command.
  def connection_options
    opts = {'u' => get_option(:user) || 'root'}
    opts['p'] = get_option(:password) if get_option(:password)
    opts['h'] = get_option(:host) if get_option(:host)
    opts['P'] = get_option(:port) if get_option(:port)
    opts['S'] = get_option(:socket) if get_option(:socket)
    
    opts.to_a.map { |o| "-#{o.first}#{o.last}"}.join(' ')
  end

end
