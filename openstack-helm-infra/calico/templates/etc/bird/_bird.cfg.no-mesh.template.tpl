# Generated by confd
include "bird_aggr.cfg";
include "custom_filters.cfg";
include "bird_ipam.cfg";
{{`{{$node_ip_key := printf "/host/%s/ip_addr_v4" (getenv "NODENAME")}}`}}{{`{{$node_ip := getv $node_ip_key}}`}}

# ensure we only listen to a specific ip and address
listen bgp address {{`{{$node_ip}}`}} port {{.Values.networking.bgp.ipv4.no_mesh.port.listen}};

router id {{`{{$node_ip}}`}};

{{`{{define "LOGGING"}}`}}
{{`{{$node_logging_key := printf "/host/%s/loglevel" (getenv "NODENAME")}}`}}{{`{{if exists $node_logging_key}}`}}{{`{{$logging := getv $node_logging_key}}`}}
{{`{{if eq $logging "debug"}}`}}  debug all;{{`{{else if ne $logging "none"}}`}}  debug { states };{{`{{end}}`}}
{{`{{else if exists "/global/loglevel"}}`}}{{`{{$logging := getv "/global/loglevel"}}`}}
{{`{{if eq $logging "debug"}}`}}  debug all;{{`{{else if ne $logging "none"}}`}}  debug { states };{{`{{end}}`}}
{{`{{else}}`}}  debug { states };{{`{{end}}`}}
{{`{{end}}`}}

# Configure synchronization between routing tables and kernel.
protocol kernel {
  learn;             # Learn all alien routes from the kernel
  persist;           # Don't remove routes on bird shutdown
  scan time 2;       # Scan kernel routing table every 2 seconds
  import all;
  export filter calico_ipip; # Default is export none
  graceful restart;  # Turn on graceful restart to reduce potential flaps in
                     # routes when reloading BIRD configuration.  With a full
                     # automatic mesh, there is no way to prevent BGP from
                     # flapping since multiple nodes update their BGP
                     # configuration at the same time, GR is not guaranteed to
                     # work correctly in this scenario.
}

# Watch interface up/down events.
protocol device {
  {{`{{template "LOGGING"}}`}}
  scan time 2;    # Scan interfaces every 2 seconds
}

protocol direct {
  {{`{{template "LOGGING"}}`}}
  interface -"cali*", "*"; # Exclude cali* but include everything else.
}

{{`{{$node_as_key := printf "/host/%s/as_num" (getenv "NODENAME")}}`}}
# Template for all BGP clients
template bgp bgp_template {
  {{`{{template "LOGGING"}}`}}
  description "Connection to BGP peer";
  local as {{`{{if exists $node_as_key}}`}}{{`{{getv $node_as_key}}`}}{{`{{else}}`}}{{`{{getv "/global/as_num"}}`}}{{`{{end}}`}};
  multihop;
  gateway recursive; # This should be the default, but just in case.
  import all;        # Import all routes, since we don't know what the upstream
                     # topology is and therefore have to trust the ToR/RR.
  export filter calico_pools;  # Only want to export routes for workloads.
  next hop self;     # Disable next hop processing and always advertise our
                     # local address as nexthop
  source address {{`{{$node_ip}}`}};  # The local address we use for the TCP connection
  add paths on;
  graceful restart;  # See comment in kernel section about graceful restart.
}


# ------------- Global peers -------------
{{`{{if ls "/global/peer_v4"}}`}}
{{`{{range gets "/global/peer_v4/*"}}`}}{{`{{$data := json .Value}}`}}
{{`{{$nums := split $data.ip "."}}`}}{{`{{$id := join $nums "_"}}`}}
# For peer {{`{{.Key}}`}}
protocol bgp Global_{{`{{$id}}`}} from bgp_template {
  neighbor {{`{{$data.ip}}`}} as {{`{{$data.as_num}}`}};
  neighbor port {{.Values.networking.bgp.ipv4.no_mesh.port.neighbor}};
}
{{`{{end}}`}}
{{`{{else}}`}}# No global peers configured.{{`{{end}}`}}


# ------------- Node-specific peers -------------
{{`{{$node_peers_key := printf "/host/%s/peer_v4" (getenv "NODENAME")}}`}}
{{`{{if ls $node_peers_key}}`}}
{{`{{range gets (printf "%s/*" $node_peers_key)}}`}}{{`{{$data := json .Value}}`}}
{{`{{$nums := split $data.ip "."}}`}}{{`{{$id := join $nums "_"}}`}}
# For peer {{`{{.Key}}`}}
protocol bgp Node_{{`{{$id}}`}} from bgp_template {
  neighbor {{`{{$data.ip}}`}} as {{`{{$data.as_num}}`}};
  neighbor port {{.Values.networking.bgp.ipv4.no_mesh.port.neighbor}};
}
{{`{{end}}`}}
{{`{{else}}`}}# No node-specific peers configured.{{`{{end}}`}}
