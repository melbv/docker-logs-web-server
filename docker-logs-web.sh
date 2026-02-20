#!/bin/bash
DOCKER="/usr/bin/docker"
JQ="/usr/bin/jq"
HEAD="/usr/bin/head"
TAIL="/usr/bin/tail"
GREP="/bin/grep"
LOG_DIR="/var/lib/docker/containers"
PORT=8080

echo "✅ Docker Logs Web Server"
echo "🌐 http://localhost:$PORT"
echo ""

trap 'exit 0' INT TERM EXIT

handle_request() {
  read -r method path proto
  while read -r line && [ -n "${line%$'\r'}" ]; do :; done
  
  echo "📝 $method $path" >&2
  
  if [ "$path" = "/favicon.ico" ]; then
    echo -ne "HTTP/1.1 404 Not Found\r\n\r\n"
    return
  fi
  
  if [ "$path" = "/" ]; then
    echo "🏠 Home" >&2
    echo -ne "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n"
    echo '<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>'
    echo '<body style="font-family:sans-serif;padding:20px"><h1>Docker Container Logs</h1><ul style="list-style:none;padding:0">'
    
    docker ps -a --no-trunc --format '{{.ID}}|{{.Names}}' | while IFS='|' read -r id name; do
      [ -f "$LOG_DIR/$id/$id-json.log" ] && echo "<li style='margin:10px 0;padding:10px;background:#f0f0f0;border-radius:5px'><a href='/$id' style='text-decoration:none;color:#0066cc;font-size:16px'>📋 $name</a><br><small style='color:#666'>ID: ${id:0:12}</small></li>"
    done
    
    echo '</ul></body></html>'
  else
    CID="${path#/}"
    LF="$LOG_DIR/$CID/$CID-json.log"
    
    [ ! -f "$LF" ] && CID=$(docker ps -a --no-trunc --filter "id=$CID" --format '{{.ID}}' | head -1) && LF="$LOG_DIR/$CID/$CID-json.log"
    
    if [ -f "$LF" ]; then
      NM=$(docker ps -a --no-trunc --filter "id=$CID" --format '{{.Names}}' | head -1)
      echo "✅ $NM" >&2
      
      echo -ne "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n"
      echo "<html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'></head><body style='font-family:sans-serif;padding:10px'><h2>📋 $NM</h2><p style='font-size:12px;color:#666'>ID: ${CID:0:12}</p><div style='margin:10px 0'><a href='/' style='padding:8px 12px;background:#0066cc;color:white;text-decoration:none;border-radius:4px;margin-right:10px'>← Back</a><a href='/$CID' style='padding:8px 12px;background:#28a745;color:white;text-decoration:none;border-radius:4px'>🔄 Refresh</a></div><hr><pre style='background:#1e1e1e;color:#d4d4d4;padding:10px;overflow-x:auto;border-radius:5px;font-size:12px;line-height:1.4'>"
      
      tail -100 "$LF" | while read -r l; do
        command -v jq >/dev/null 2>&1 && echo "$l" | jq -r '.log//empty' 2>/dev/null || echo "$l"
      done | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g'
      
      echo '</pre></body></html>'
    else
      echo "❌ Not found" >&2
      echo -ne "HTTP/1.1 404 Not Found\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n"
      echo "<html><body><h1>❌ Not found</h1><p><a href='/'>Back</a></p></body></html>"
    fi
  fi
}

while true; do
  mkfifo /tmp/ncpipe$$ 2>/dev/null
  handle_request < /tmp/ncpipe$$ | nc -l -s 0.0.0.0 -p $PORT > /tmp/ncpipe$$
  rm -f /tmp/ncpipe$$
  echo "---" >&2
done
